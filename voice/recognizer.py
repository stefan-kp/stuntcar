"""Local English speech input. Audio remains in memory and is never saved."""
import argparse
from array import array
from collections import deque
import json
from pathlib import Path
import queue
import select
import socket
import shutil
import tempfile
import time
import wave

if __package__:
    from .runtime_paths import model_root
    from .protocol import choose_command
    from .streaming import StreamingRecognizer
else:
    from runtime_paths import model_root
    from protocol import choose_command
    from streaming import StreamingRecognizer

SAMPLE_RATE = 16000
BLOCK = 800
MODEL_ROOT = model_root()
GRAMMARS = {
    'de': ['links', 'rechts', 'schneller', 'langsamer', 'gas', 'gas geben', 'bremsen', 'bremse',
           'pause', 'weiter', 'nächstes', 'wählen', 'start', 'starten', '[unk]'],
    'en-us': ['left', 'right', 'fast', 'faster', 'slower', 'gas', 'brake', 'brakes', 'accelerate', 'throttle',
              'pause', 'continue', 'resume', 'next', 'select', 'start', '[unk]'],
}


class VoiceError(RuntimeError):
    """A user-facing error code that Godot translates."""


class BilingualRecognizer:
    def __init__(self, languages=('de', 'en-us'), frames_per_chunk=None, mode='checked'):
        if mode not in ('direct', 'checked'):
            raise ValueError('Unknown recognition mode: ' + str(mode))
        self.mode = mode
        import vosk
        vosk.SetLogLevel(-1)
        self.recognizers = []
        self.fallback_recognizers = []
        for language in languages:
            path = MODEL_ROOT / f'vosk-model-small-{language}-0.15'
            if not path.is_dir():
                raise VoiceError('I18N_VOICE_MODEL_MISSING')
            if frames_per_chunk is None:
                model = vosk.Model(str(path))
            else:
                # Keep downloaded weights/configuration intact, including other
                # processes and historical benchmarks. Vosk loads files eagerly.
                with tempfile.TemporaryDirectory(prefix='stuntcar-vosk-') as folder:
                    configured = Path(folder) / 'model'
                    shutil.copytree(path, configured)
                    with (configured / 'conf/model.conf').open('a') as config:
                        config.write(f'\n--frames-per-chunk={frames_per_chunk}\n')
                    model = vosk.Model(str(configured))
            recognizer = (vosk.KaldiRecognizer(model, SAMPLE_RATE) if mode == 'direct' else
                          vosk.KaldiRecognizer(model, SAMPLE_RATE, json.dumps(GRAMMARS[language], ensure_ascii=False)))
            recognizer.SetWords(True)
            self.recognizers.append(recognizer)
            if mode == 'checked':
                fallback = vosk.KaldiRecognizer(model, SAMPLE_RATE)
                fallback.SetWords(True)
                self.fallback_recognizers.append(fallback)

    def recognize(self, pcm):
        # Real microphone input has pre-roll. Padding also protects a clipped onset.
        pcm = bytes(6400) + pcm
        results = self.decode(self.recognizers, pcm)
        chosen = choose_command(results)
        if chosen is None:
            fallback_results = self.decode(self.fallback_recognizers, pcm)
            fallback = choose_command(fallback_results)
            # A free recognizer may resolve a language conflict, but only when
            # the command also appears in the restricted recognizer's words.
            if fallback and any(fallback[1] in result.get('text', '').split('[unk]')
                                or fallback[1] == result.get('text', '').replace('[unk]', '').strip()
                                for result in results):
                chosen = fallback
            results += fallback_results
        return chosen, results

    @staticmethod
    def decode(recognizers, pcm):
        results = []
        for recognizer in recognizers:
            recognizer.Reset()
            if recognizer.AcceptWaveform(pcm):
                results.append(json.loads(recognizer.Result()))
            else:
                results.append(json.loads(recognizer.FinalResult()))
        return results


class EnglishRecognizer(BilingualRecognizer):
    """One free English decoder or two checked decoders, with 60 ms chunks."""
    def __init__(self, mode='checked'):
        super().__init__(languages=('en-us',), frames_per_chunk=6, mode=mode)


class Segmenter:
    """A short silence completes a command; no partial words steer the car."""
    def __init__(self):
        self.reset()

    def reset(self):
        self.pre_roll = deque(maxlen=3)
        self.parts = []
        self.silent_blocks = 0
        self.speech_blocks = 0

    def feed(self, pcm):
        samples = array('h', pcm)
        rms = (sum(value * value for value in samples) / max(1, len(samples))) ** .5
        speech = rms >= 180
        if not self.parts:
            self.pre_roll.append(pcm)
            if not speech:
                return None, rms
            self.parts = list(self.pre_roll)
            self.speech_blocks = 1
        else:
            self.parts.append(pcm)
            if speech:
                self.speech_blocks += 1
        self.silent_blocks = 0 if speech else self.silent_blocks + 1
        if len(self.parts) > 80:
            self.reset()
            return None, rms
        if self.silent_blocks >= 6:
            utterance = b''.join(self.parts) if self.speech_blocks >= 2 else None
            self.reset()
            return utterance, rms
        return None, rms


class Connection:
    def __init__(self, port, token):
        self.socket = socket.create_connection(('127.0.0.1', port), timeout=2)
        self.socket.settimeout(.5)
        self.seq = 0
        self.epoch = 0
        self.buffer = b''
        self.call_context = {}
        self.call_context_time = 0.0
        self.send('hello', token=token)

    def send(self, kind, **values):
        self.seq += 1
        data = {'type': kind, 'seq': self.seq, 'epoch': self.epoch, **values}
        self.socket.sendall((json.dumps(data, ensure_ascii=False) + '\n').encode())

    def poll(self):
        before = self.epoch
        while select.select([self.socket], [], [], 0)[0]:
            chunk = self.socket.recv(4096)
            if not chunk:
                raise ConnectionError('Das Spiel hat die Verbindung beendet.')
            self.buffer += chunk
            if len(self.buffer) > 8192:
                raise ConnectionError('Ungültige Nachricht vom Spiel.')
            while b'\n' in self.buffer:
                line, self.buffer = self.buffer.split(b'\n', 1)
                data = json.loads(line)
                if data.get('type') == 'context' and isinstance(data.get('epoch'), int):
                    self.epoch = data['epoch']
                elif data.get('type') == 'call_context' and data.get('epoch') == self.epoch:
                    self.call_context = data
                    self.call_context_time = time.monotonic()
        return self.epoch != before


def run_microphone(connection, device=None, mode='checked'):
    import sounddevice as sd
    connection.send('loading')
    engine = EnglishRecognizer(mode=mode)
    device_info = sd.query_devices(device, 'input')
    audio_queue = queue.Queue(maxsize=20)
    problems = queue.Queue(maxsize=1)

    def callback(data, frames, timing, status):
        if status:
            try: problems.put_nowait('I18N_VOICE_AUDIO_LATE')
            except queue.Full: pass
        try:
            audio_queue.put_nowait((time.monotonic(), bytes(data)))
        except queue.Full:
            try: problems.put_nowait('I18N_VOICE_DELAY')
            except queue.Full: pass

    with sd.RawInputStream(samplerate=SAMPLE_RATE, blocksize=BLOCK, device=device,
                           dtype='int16', channels=1, callback=callback):
        connection.send('ready', device=str(device_info['name'])[:60], mode=mode)
        stream = StreamingRecognizer(engine)
        last_feedback = 0.0
        last_heartbeat = 0.0
        last_audio = time.monotonic()
        cutoff = last_audio
        while True:
            if connection.poll():
                stream.reset()
                cutoff = time.monotonic()
            if not problems.empty():
                raise VoiceError(problems.get_nowait())
            now = time.monotonic()
            if now - last_audio > 2:
                raise VoiceError('I18N_VOICE_NO_AUDIO')
            if now - last_heartbeat >= 1:
                connection.send('heartbeat')
                last_heartbeat = now
            try:
                captured, pcm = audio_queue.get(timeout=.05)
            except queue.Empty:
                continue
            last_audio = now
            if captured < cutoff:
                continue
            if now - captured > .4:
                raise VoiceError('I18N_VOICE_DELAY')
            epoch = connection.epoch
            context = connection.call_context
            if context:
                stream.configure_call(context.get('profile', {}), context.get('opportunity_id', -1))
            eligible = context.get("opportunity_id", -1) if captured >= connection.call_context_time else -1
            commands, feedback = stream.feed(pcm, eligible)
            if connection.poll():
                stream.reset()
                cutoff = time.monotonic()
            if epoch != connection.epoch:
                continue
            for command in commands:
                connection.send('command', **command)
            if context.get('practice', False) or now - last_feedback >= .1 or commands or feedback['state'] in ('recognized', 'unknown'):
                connection.send('feedback', sample_seconds=len(pcm) / 32000, **feedback)
                last_feedback = now


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check-runtime', action='store_true')
    parser.add_argument('--port', type=int)
    parser.add_argument('--token')
    parser.add_argument('--device', type=int)
    parser.add_argument('--wav', type=Path)
    parser.add_argument('--mode', choices=('direct', 'checked'), default='checked')
    args = parser.parse_args()
    if args.check_runtime:
        import sounddevice as sd
        EnglishRecognizer(mode=args.mode)
        print(json.dumps({'model_found': True, 'sounddevice_version': sd.__version__, 'host_apis': len(sd.query_hostapis())}))
        return
    if args.wav:
        with wave.open(str(args.wav), 'rb') as source:
            if (source.getframerate(), source.getnchannels(), source.getsampwidth()) != (16000, 1, 2):
                raise ValueError('Die Testdatei braucht 16 kHz, einen Kanal und 16 Bit.')
            pcm = source.readframes(source.getnframes())
        chosen, results = EnglishRecognizer(mode=args.mode).recognize(pcm)
        print(json.dumps({'chosen': chosen, 'results': results}, ensure_ascii=False))
        return
    if not args.port or not args.token:
        parser.error('Das Spiel muss Anschluss und Kennung übergeben.')
    connection = Connection(args.port, args.token)
    try:
        run_microphone(connection, args.device, mode=args.mode)
    except (BrokenPipeError, ConnectionError):
        pass
    except Exception as error:
        message = str(error)
        if not isinstance(error, VoiceError):
            message = 'I18N_VOICE_UNAVAILABLE'
        try: connection.send('error', message=message[:180])
        except OSError: pass
    finally:
        connection.socket.close()

if __name__ == '__main__':
    main()
