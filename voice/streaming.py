"""Incremental commands with per-word confirmation and no final-result replay."""
from array import array
from collections import deque
import json

if __package__:
    from .protocol import normalize_command
    from .call_detector import CallDetector
else:
    from protocol import normalize_command
    from call_detector import CallDetector

DRIVING = {'left', 'right', 'faster', 'slower', 'pause'}


def command_words(text, confirmation=False):
    """Reject unknown words; treat 'gas geben' as one command."""
    words = text.split()
    result = []
    index = 0
    while index < len(words):
        word = words[index]
        if word == 'gas' and index + 1 < len(words) and words[index + 1] == 'geben':
            word = 'gas geben'
            index += 1
        # The free German decoder can omit the final r in repeated "langsamer".
        # Accept this acoustic variant only as confirmation of the restricted
        # decoder's exact command. It never becomes a standalone command.
        command = 'slower' if confirmation and word == 'langsame' else normalize_command(word)
        if command is None:
            return []
        result.append({'command': command, 'text': word})
        index += 1
    return result


def codes(words):
    return [word['command'] for word in words]


class StreamingRecognizer:
    def __init__(self, engine):
        self.calls = CallDetector()
        self.call_context = False
        self.opportunity_id = -1
        self.event_serial = 0
        self.engine = engine
        self.mode = getattr(engine, 'mode', 'checked')
        self.reset()

    def configure_call(self, profile, opportunity_id):
        self.call_context = True
        self.calls.configure(profile)
        self.opportunity_id = opportunity_id

    def reset_call(self):
        self.speech_seconds = 0.0
        self.call_peak_rms = 0.0
        self.call_silent_blocks = 0
        self.call_has_command = False

    def reset(self, preserve_call=False):
        if not preserve_call:
            self.reset_call()
            self.calls.reset()
        self.restricted_count = len(self.engine.recognizers) if self.mode == 'checked' else 0
        self.decoders = self.engine.recognizers + self.engine.fallback_recognizers
        for decoder in self.decoders:
            decoder.Reset()
            decoder.AcceptWaveform(bytes(6400))
        self.completed_text = [''] * len(self.decoders)
        self.completed_words = [[] for _ in range(len(self.decoders))]
        self.decoder_ended = [False] * len(self.decoders)
        self.pre_roll = deque(maxlen=3)
        self.parts = []
        self.active = False
        self.silent_blocks = 0
        self.elapsed = 0.0
        self.emitted = []
        self.candidates = []
        self.since = []
        self.heard = ''
        self.recent_levels = deque()
        self.pending_peak_rms = 0.0
        self.recent_clips = deque()

    def confirmed(self, results):
        if self.mode == 'direct':
            # Check every word of the free transcript, including unknown prefixes.
            return command_words(results[0].get('partial', results[0].get('text', ''))) if results else []
        options = []
        restricted = [result.get('_words', command_words(result.get('partial', result.get('text', ''))))
                      for result in results[:self.restricted_count]]
        for result in results[self.restricted_count:]:
            free = result.get('_words', command_words(result.get('partial', result.get('text', ''))))
            if free and any(codes(words[:len(free)]) == codes(free)
                            or codes(words[-len(free):]) == codes(free) for words in restricted):
                options.append(free)
        if not options:
            return []
        options.sort(key=len, reverse=True)
        if any(codes(options[0][:len(other)]) != codes(other) for other in options[1:]):
            return []
        return options[0]

    def new_commands(self, words, final=False):
        commands = codes(words)
        if commands[:len(self.emitted)] != self.emitted:
            self.candidates, self.since = [], []
            return []
        times = []
        for index, command in enumerate(commands):
            times.append(self.since[index] if index < len(self.candidates)
                         and self.candidates[:index + 1] == commands[:index + 1] else self.elapsed)
        self.candidates, self.since = commands, times
        events = []
        for index in range(len(self.emitted), len(words)):
            if not final and (commands[index] not in DRIVING or
                              self.mode == 'checked' and self.elapsed - times[index] < .049):
                break
            event = dict(words[index])
            self.event_serial += 1
            event["event_id"] = str(self.event_serial)
            # Hold the spoken peak until the decoder releases the command.
            # Its onset can precede recognition by more than the live meter window.
            # Keep the short overlap too: the next word may already have started
            # when the decoder releases the previous word.
            event['peak_rms'] = max(self.pending_peak_rms,
                                    max((level for _, level in self.recent_levels), default=0.0))
            event['strength'] = min(1.0, event['peak_rms'] / 3000)
            events.append(event)
            self.emitted.append(commands[index])
        return events

    def feed(self, pcm, call_opportunity_id=None):
        samples = array('h', pcm)
        rms = (sum(value * value for value in samples) / max(1, len(samples))) ** .5
        self.elapsed += len(pcm) / 32000
        self.pending_peak_rms = max(self.pending_peak_rms, rms)
        self.recent_levels.append((self.elapsed, rms))
        clipped = sum(abs(value) >= 32760 for value in samples) >= max(1, len(samples) * .02)
        self.recent_clips.append((self.elapsed, clipped))
        while self.recent_levels and self.recent_levels[0][0] < self.elapsed - .45:
            self.recent_levels.popleft()
        while self.recent_clips and self.recent_clips[0][0] < self.elapsed - .45:
            self.recent_clips.popleft()
        self.pre_roll.append(pcm)
        if rms >= 180:
            self.speech_seconds += len(pcm) / 32000
            self.call_peak_rms = max(self.call_peak_rms, rms)
            self.call_silent_blocks = 0
            if not self.active:
                self.parts = list(self.pre_roll)[:-1]
            self.active = True
            self.silent_blocks = 0
        elif self.active:
            self.silent_blocks += 1
        if rms < 180 and self.speech_seconds > 0:
            self.call_silent_blocks += 1
        if self.active and len(self.parts) < 300:
            self.parts.append(pcm)
        results = []
        for index, decoder in enumerate(self.decoders):
            final = decoder.AcceptWaveform(pcm)
            result = json.loads(decoder.Result() if final else decoder.PartialResult())
            text = result.get('text', result.get('partial', ''))
            joined = (self.completed_text[index] + ' ' + text).strip()
            words = self.completed_words[index] + command_words(text, confirmation=index >= self.restricted_count)
            results.append({'partial': joined, '_words': words})
            if final:
                # Vosk starts another result even when ambient sound keeps RMS high.
                # Keep word positions so a later repeated word is still a new input.
                self.completed_text[index] = joined
                self.completed_words[index] = words
                self.decoder_ended[index] = True
            elif text:
                self.decoder_ended[index] = False
        confirmed = self.confirmed(results)
        # Free text explains rejected speech. Restricted guesses remain provisional.
        texts = [result.get('partial', result.get('text', '')) for result in results]
        self.heard = ' '.join(word['text'] for word in confirmed) if confirmed else next(
            (text for text in texts[self.restricted_count:] if text), next((text for text in texts if text), ''))
        events = self.new_commands(confirmed) if self.active else []
        status = {'heard': self.heard[-70:], 'level': min(1.0, rms / 3000), 'state': 'listening',
                  'clipped': any(value for _, value in self.recent_clips),
                  'rms': rms, 'peak_rms': max((level for _, level in self.recent_levels), default=0.0)}
        status['direction'] = (confirmed[-1]['command'] if confirmed and rms >= 180
                               and confirmed[-1]['command'] in {'left', 'right', 'faster', 'slower'} else '')
        if self.active:
            status['state'] = 'checking'
        if self.active and (self.silent_blocks >= 6 or all(self.decoder_ended)):
            finals = []
            for index, decoder in enumerate(self.decoders):
                result = json.loads(decoder.FinalResult())
                result['_words'] = self.completed_words[index] + command_words(result.get('text', ''), confirmation=index >= self.restricted_count)
                result['text'] = (self.completed_text[index] + ' ' + result.get('text', '')).strip()
                finals.append(result)
            words = self.confirmed(finals)
            if not words and len(self.parts) < 300:
                chosen, _ = self.engine.recognize(b''.join(self.parts))
                if chosen:
                    words = [{'command': chosen[0], 'text': chosen[1]}]
            events += self.new_commands(words, final=True)
            status['state'] = 'recognized' if self.emitted else 'unknown'
            self.reset(preserve_call=True)
        self.call_has_command = self.call_has_command or bool(events)
        if self.speech_seconds > 0 and self.call_silent_blocks >= 6:
            # Decoder endpoints can split one continuous call. Only an acoustic
            # pause permits help, and any command in the whole call takes priority.
            status['state'] = 'recognized' if self.call_has_command else 'unknown'
            if not self.call_has_command:
                status['peak_rms'] = self.call_peak_rms
                status['speech_seconds'] = self.speech_seconds
            self.reset_call()
        if events:
            # All commands released in this block share its available measurement.
            # Do not carry it into the next command.
            self.pending_peak_rms = 0.0
        if events and events[-1]['command'] in {'left', 'right', 'faster', 'slower'}:
            status['direction'] = events[-1]['command']
        if self.call_context:
            status.pop('speech_seconds', None)
            opportunity = self.opportunity_id if call_opportunity_id is None else call_opportunity_id
            call = self.calls.feed(pcm, opportunity, bool(events))
            if call:
                status.update(call)
                status['state'] = 'unknown'
        return events, status
