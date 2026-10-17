"""Mode boundaries independent of speech model timing."""
from array import array
import json
from types import SimpleNamespace
import unittest

from voice.streaming import StreamingRecognizer, command_words


class Decoder:
    """Feed complete Vosk-shaped partial and final packets to the real stream."""
    def __init__(self):
        self.text = ''
        self.final = False

    def Reset(self):
        self.text = ''
        self.final = False

    def AcceptWaveform(self, pcm):
        return self.final

    def PartialResult(self):
        return json.dumps({'partial': self.text})

    def Result(self):
        self.final = False
        result = json.dumps({'text': self.text})
        self.text = ''
        return result

    def FinalResult(self):
        return json.dumps({'text': self.text})


class RecognitionModes(unittest.TestCase):
    def stream(self, mode):
        decoder = Decoder()
        fallback = Decoder()
        engine = SimpleNamespace(mode=mode, recognizers=[decoder],
                                 fallback_recognizers=[fallback] if mode == 'checked' else [],
                                 recognize=lambda pcm: (None, []))
        return StreamingRecognizer(engine), decoder, fallback

    def feed(self, stream, decoder, text, fallback=None):
        decoder.text = text
        if fallback:
            fallback.text = text
        return stream.feed(array('h', [1500] * 800).tobytes())

    def test_direct_acts_on_first_free_word_without_stability_wait(self):
        stream, decoder, _ = self.stream('direct')
        events, status = self.feed(stream, decoder, 'left')
        self.assertEqual([event['command'] for event in events], ['left'])
        self.assertEqual(status['direction'], 'left')
        self.assertEqual(events[0]['strength'], .5)

    def test_spoken_faster_variants_preserve_repeats_without_double_action(self):
        for variant in ('fasta', 'foster'):
            stream, decoder, _ = self.stream('direct')
            events, _ = self.feed(stream, decoder, variant)
            self.assertEqual([event['command'] for event in events], ['faster'])
            events, _ = self.feed(stream, decoder, 'faster')
            self.assertEqual(events, [])
            events, _ = self.feed(stream, decoder, 'faster foster')
            self.assertEqual([event['command'] for event in events], ['faster'])
        stream, decoder, fallback = self.stream('checked')
        decoder.text, fallback.text = 'faster', 'foster'
        self.assertEqual(stream.feed(array('h', [1500] * 800).tobytes())[0], [])
        events, _ = stream.feed(array('h', [1500] * 800).tobytes())
        self.assertEqual([event['command'] for event in events], ['faster'])

    def test_similar_words_do_not_turn_unknown_sentences_into_commands(self):
        for text in ('my foster brother', 'not foster', 'fasta please', 'father', 'after', 'cause'):
            stream, decoder, _ = self.stream('direct')
            self.assertEqual(self.feed(stream, decoder, text)[0], [], text)

    def test_close_driving_word_acts_without_wait_or_duplicate_event(self):
        stream, decoder, _ = self.stream('direct')
        events, _ = self.feed(stream, decoder, 'light')
        self.assertEqual([event['command'] for event in events], ['right'])
        for text in ('right', 'righht'):
            self.assertEqual(self.feed(stream, decoder, text)[0], [])
        events, _ = self.feed(stream, decoder, 'right light')
        self.assertEqual([event['command'] for event in events], ['right'])
        self.assertEqual(self.feed(stream, decoder, 'righht right')[0], [])

    def test_command_words_preserve_close_repeated_commands(self):
        self.assertEqual(command_words('faste fastter slowwer'), [
            {'command': 'faster', 'text': 'faste'},
            {'command': 'faster', 'text': 'fastter'},
            {'command': 'slower', 'text': 'slowwer'},
        ])

    def test_close_words_in_full_unknown_text_do_not_emit(self):
        for text in ('not light', 'light please', 'my slowwer brother',
                     'paus', 'nexxt', 'resum', 'stat', 'selekt'):
            stream, decoder, _ = self.stream('direct')
            self.assertEqual(self.feed(stream, decoder, text)[0], [], text)

    def test_checked_keeps_stability_wait(self):
        stream, decoder, fallback = self.stream('checked')
        events, _ = self.feed(stream, decoder, 'left', fallback)
        self.assertEqual(events, [])
        events, _ = self.feed(stream, decoder, 'left', fallback)
        self.assertEqual([event['command'] for event in events], ['left'])

    def test_direct_emits_each_repeat_once_and_reset_discards_old_words(self):
        stream, decoder, _ = self.stream('direct')
        events = []
        for text in ('left', 'left', 'left left', 'left left right fast slower'):
            emitted, _ = self.feed(stream, decoder, text)
            events.extend(event['command'] for event in emitted)
        self.assertEqual(events, ['left', 'left', 'right', 'faster', 'slower'])
        stream.reset()
        events, _ = stream.feed(bytes(1600))
        self.assertEqual(events, [])
        events, _ = self.feed(stream, decoder, 'right')
        self.assertEqual([event['command'] for event in events], ['right'])

    def test_direct_menu_waits_for_utterance_end(self):
        stream, decoder, _ = self.stream('direct')
        events, _ = self.feed(stream, decoder, 'start')
        self.assertEqual(events, [])
        events = []
        for _ in range(6):
            emitted, _ = stream.feed(bytes(1600))
            events.extend(event['command'] for event in emitted)
        self.assertEqual(events, ['start'])

    def test_direct_rejects_full_unknown_text_including_previous_decoder_result(self):
        for text in ('not left', 'left turn', 'hello right', 'langsame', '[unk] left'):
            stream, decoder, _ = self.stream('direct')
            events, _ = self.feed(stream, decoder, text)
            self.assertEqual(events, [], text)
        stream, _, _ = self.stream('direct')
        # Cached command words must not hide unknown words in the full transcript.
        self.assertEqual(stream.confirmed([{'partial': 'not left', '_words': command_words('left')}]), [])

    def test_unknown_retains_shout_peak_until_end_even_without_text(self):
        for mode in ('direct', 'checked'):
            for text in ('', 'updi dupdi'):
                with self.subTest(mode=mode, text=text):
                    stream, decoder, fallback = self.stream(mode)
                    decoder.text = fallback.text = text
                    stream.feed(array('h', [9000] * 800).tobytes())
                    # The peak leaves the live meter before the utterance ends.
                    for _ in range(12):
                        events, status = stream.feed(array('h', [500] * 800).tobytes())
                        self.assertEqual(events, [])
                        self.assertEqual(status['state'], 'checking')
                    for _ in range(6):
                        events, status = stream.feed(bytes(1600))
                        self.assertEqual(events, [])
                    self.assertEqual(status['state'], 'unknown')
                    self.assertEqual(status['peak_rms'], 9000)
                    self.assertAlmostEqual(status.get('speech_seconds', -1), .65)
                    for _ in range(10):
                        _, status = stream.feed(bytes(1600))
                        self.assertEqual(status['state'], 'listening')
                    for _ in range(4):
                        stream.feed(array('h', [500] * 800).tobytes())
                    for _ in range(6):
                        _, status = stream.feed(bytes(1600))
                    self.assertEqual(status['state'], 'unknown')
                    self.assertEqual(status['peak_rms'], 500)
                    self.assertAlmostEqual(status['speech_seconds'], .2)

    def test_recognized_word_does_not_end_as_unknown(self):
        stream, decoder, _ = self.stream('direct')
        events, _ = self.feed(stream, decoder, 'left')
        self.assertEqual([event['command'] for event in events], ['left'])
        decoder.text = 'updi dupdi'
        for _ in range(6):
            events, status = stream.feed(bytes(1600))
            self.assertEqual(events, [])
        self.assertEqual(status['state'], 'recognized')

    def test_decoder_boundaries_do_not_split_one_call_into_several_assists(self):
        stream, decoder, _ = self.stream('direct')
        for level in (9000, 500):
            for _ in range(3):
                _, status = stream.feed(array('h', [level] * 800).tobytes())
                self.assertEqual(status.get('speech_seconds', 0), 0)
            decoder.final = True
            _, status = stream.feed(array('h', [level] * 800).tobytes())
            self.assertEqual(status.get('speech_seconds', 0), 0,
                             'A decoder boundary is not a pause in a continuous call.')
        for _ in range(6):
            _, status = stream.feed(bytes(1600))
        self.assertEqual(status['state'], 'unknown')
        self.assertEqual(status['peak_rms'], 9000)
        self.assertAlmostEqual(status['speech_seconds'], .4)
        for _ in range(6):
            _, status = stream.feed(bytes(1600))
            self.assertEqual(status.get('speech_seconds', 0), 0)

    def test_command_before_decoder_boundary_suppresses_call_assist(self):
        stream, decoder, _ = self.stream('direct')
        events, _ = self.feed(stream, decoder, 'left')
        self.assertEqual([event['command'] for event in events], ['left'])
        decoder.final = True
        stream.feed(array('h', [9000] * 800).tobytes())
        for _ in range(4):
            stream.feed(array('h', [9000] * 800).tobytes())
        for _ in range(6):
            _, status = stream.feed(bytes(1600))
        self.assertEqual(status['state'], 'recognized')
        self.assertEqual(status.get('speech_seconds', 0), 0)


if __name__ == '__main__':
    unittest.main()
