"""Test queued audio at a game context change without opening a microphone."""
from array import array
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from voice.recognizer import BLOCK, run_microphone


class MicrophoneContext(unittest.TestCase):
    def test_context_change_during_decode_discards_old_audio(self):
        for mode, fresh_audio in ((mode, fresh) for mode in ('direct', 'checked') for fresh in (False, True)):
            with self.subTest(mode=mode, fresh_audio=fresh_audio):
                clock = [100.0]
                sent = []
                decoded = []
                callbacks = []
                blocks = [array('h', [1000] * BLOCK).tobytes()] * 2 + [bytes(BLOCK * 2)] * 6

                def feed_word():
                    for block in blocks:
                        callbacks[0](block, BLOCK, None, False)

                class InputStream:
                    def __init__(self, **kwargs):
                        callbacks.append(kwargs['callback'])

                    def __enter__(self):
                        feed_word()
                        feed_word()
                        return self

                    def __exit__(self, *args):
                        return False

                class Stream:
                    def __init__(self, engine):
                        if engine.mode != mode:
                            raise AssertionError('Wrong recognition mode')
                        self.reset()

                    def reset(self):
                        self.blocks = 0

                    def configure_call(self, profile, opportunity_id):
                        self.opportunity_id = opportunity_id

                    def feed(self, pcm, call_opportunity_id=None):
                        self.blocks += 1
                        events = []
                        if self.blocks == 8:
                            decoded.append(pcm)
                            clock[0] = max(clock[0], 100.2)
                            events = [dict(command='resume', text='weiter')]
                            self.blocks = 0
                        return events, dict(heard='', level=0, state='listening')

                class Connection:
                    epoch = 0
                    call_context = {}
                    call_context_time = 0.0
                    polls = 0

                    def send(self, kind, **values):
                        sent.append({'type': kind, 'epoch': self.epoch, **values})

                    def poll(self):
                        self.polls += 1
                        if self.polls == 50:
                            raise StopIteration
                        if fresh_audio and self.polls == 20:
                            clock[0] = 100.3
                            feed_word()
                        if clock[0] >= 100.2 and self.epoch == 0:
                            self.epoch = 1
                            return True
                        return False

                audio = SimpleNamespace(RawInputStream=InputStream,
                                        query_devices=lambda *args: {'name': 'Test'})
                with patch.dict('sys.modules', {'sounddevice': audio}), \
                        patch('voice.recognizer.EnglishRecognizer', lambda mode: SimpleNamespace(mode=mode)), \
                        patch('voice.recognizer.StreamingRecognizer', Stream), \
                        patch('voice.recognizer.time.monotonic', lambda: clock[0]):
                    with self.assertRaises(StopIteration):
                        run_microphone(Connection(), mode=mode)
                ready = [packet for packet in sent if packet['type'] == 'ready']
                self.assertEqual(ready, [dict(type='ready', epoch=0, device='Test', mode=mode)])
                commands = [packet for packet in sent if packet['type'] == 'command']
                self.assertEqual(len(decoded), 2 if fresh_audio else 1)
                self.assertEqual(commands, [dict(type='command', epoch=1, command='resume', text='weiter')]
                                 if fresh_audio else [])
