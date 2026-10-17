from pathlib import Path
from array import array
import unittest
import importlib

class CallDetectorTests(unittest.TestCase):
    def detector(self):
        self.assertTrue((Path(__file__).parents[1]/'call_detector.py').is_file(), 'Die Erkennung leiser Rufe fehlt.')
        cls = importlib.import_module('voice.call_detector').CallDetector
        d=cls();d.configure(dict(version=1,device='quiet',on_rms=25.,off_rms=15.,min_call_s=.15,max_call_s=3.,release_s=.3))
        return d
    def feed(self,d,volume,count,op=1,command=False):
        events=[]
        for _ in range(count):
            e=d.feed(array('h',[volume]*800).tobytes(),op,command)
            if e:events.append(e)
        return events
    def test_quiet_call_below_old_threshold_once(self):
        d=self.detector();self.assertEqual(self.feed(d,45,6),[])
        events=self.feed(d,5,10)
        self.assertEqual(len(events),1);self.assertEqual(events[0]['opportunity_id'],1)
        self.assertEqual(self.feed(d,5,20),[])
    def test_noise_short_and_continuous_calls_never_steer(self):
        for volume,count in [(5,50),(45,1),(45,80)]:
            d=self.detector();self.assertEqual(self.feed(d,volume,count)+self.feed(d,5,10),[])
    def test_any_recognized_command_has_priority(self):
        d=self.detector();self.feed(d,45,5);self.feed(d,45,1,command=True)
        self.assertEqual(self.feed(d,5,10),[])
    def test_call_cannot_move_to_next_opportunity(self):
        d=self.detector();self.feed(d,45,4,op=1);self.feed(d,45,4,op=2)
        self.assertEqual(self.feed(d,5,10,op=2)[0]['opportunity_id'],1)
    def test_call_before_window_has_no_retroactive_grant(self):
        d=self.detector();self.feed(d,45,6,op=-1)
        self.assertEqual(self.feed(d,5,10,op=3),[])
    def test_invalid_profile_is_disabled(self):
        d=self.detector();d.configure({'on_rms':float('nan')})
        self.assertEqual(self.feed(d,45,6)+self.feed(d,5,10),[])

class CallStreamTests(unittest.TestCase):
    def test_quiet_call_survives_word_filter_and_decoder_end(self):
        from voice.tests.test_modes import RecognitionModes
        for mode in ('direct','checked'):
            stream,decoder,fallback=RecognitionModes().stream(mode)
            self.assertTrue(hasattr(stream,'configure_call'),'Der Rufkontext fehlt im Audiostrom.')
            stream.configure_call(dict(version=1,device='quiet',on_rms=25.,off_rms=15.,min_call_s=.15,max_call_s=3.,release_s=.3),7)
            statuses=[]
            for i in range(8):
                decoder.final = i==3
                statuses.append(stream.feed(array('h',[45]*800).tobytes())[1])
            for _ in range(10):statuses.append(stream.feed(array('h',[5]*800).tobytes())[1])
            calls=[x for x in statuses if 'call_id' in x]
            self.assertEqual(len(calls),1)
            self.assertEqual(calls[0]['opportunity_id'],7)
    def test_speed_word_prevents_unknown_help(self):
        from voice.tests.test_modes import RecognitionModes
        stream,decoder,_=RecognitionModes().stream('direct')
        self.assertTrue(hasattr(stream,'configure_call'),'Der Rufkontext fehlt im Audiostrom.')
        stream.configure_call(dict(version=1,device='quiet',on_rms=25.,off_rms=15.,min_call_s=.15,max_call_s=3.,release_s=.3),7)
        decoder.text='faster'
        commands,status=stream.feed(array('h',[1500]*800).tobytes())
        self.assertEqual([x['command'] for x in commands],['faster'])
        for _ in range(10):
            _,status=stream.feed(array('h',[5]*800).tobytes())
            self.assertNotIn('call_id',status)

class CallPriorityRegression(unittest.TestCase):
    def profile(self, on=25., off=15., release=.3):
        return dict(version=1, device='quiet', on_rms=on, off_rms=off,
                    min_call_s=.15, max_call_s=3., release_s=release)

    def pcm(self, rms):
        return array('h', [rms] * 800).tobytes()

    def test_quiet_speed_word_has_priority_with_and_without_call_permission(self):
        from voice.tests.test_modes import RecognitionModes
        for mode in ('direct', 'checked'):
            for opportunity in (7, -1):
                with self.subTest(mode=mode, opportunity=opportunity):
                    stream, decoder, fallback = RecognitionModes().stream(mode)
                    stream.configure_call(self.profile(), opportunity)
                    commands, calls = [], []
                    decoder.text = fallback.text = 'faster'
                    for volume in [45] * 8 + [5] * 10:
                        words, status = stream.feed(self.pcm(volume))
                        commands.extend(words)
                        if 'call_id' in status: calls.append(status)
                    self.assertEqual([word['command'] for word in commands], ['faster'])
                    self.assertEqual(calls, [])

    def test_personal_call_end_finishes_word_check_before_unknown_help(self):
        import json
        from voice.tests.test_modes import RecognitionModes
        for mode in ('direct', 'checked'):
            for release in (.15, .3):
                with self.subTest(mode=mode, release=release):
                    stream, decoder, fallback = RecognitionModes().stream(mode)
                    stream.configure_call(self.profile(850., 525., release), 7)
                    decoder.FinalResult = fallback.FinalResult = lambda: json.dumps({'text': 'faster'})
                    commands, calls = [], []
                    for volume in [1500] * 8 + [200] * 10:
                        words, status = stream.feed(self.pcm(volume))
                        commands.extend(words)
                        if 'call_id' in status: calls.append(status)
                    self.assertEqual([word['command'] for word in commands], ['faster'])
                    self.assertEqual(calls, [])

    def test_room_noise_cannot_release_a_second_late_action(self):
        from voice.tests.test_modes import RecognitionModes
        for mode in ('direct', 'checked'):
            stream, decoder, fallback = RecognitionModes().stream(mode)
            stream.configure_call(self.profile(850.,525.),7)
            actions=[]
            for volume in [1500]*8+[200]*6:
                words,status=stream.feed(self.pcm(volume));actions.extend(words)
                if 'call_id' in status:actions.append(status)
            decoder.text=fallback.text='faster'
            for _ in range(3):
                words,status=stream.feed(self.pcm(200));actions.extend(words)
                if 'call_id' in status:actions.append(status)
            self.assertEqual(len(actions),1,mode)

    def test_long_call_keeps_its_duration_when_opportunity_opens(self):
        from voice.tests.test_modes import RecognitionModes
        for mode in ('direct','checked'):
            stream,_,_=RecognitionModes().stream(mode)
            stream.configure_call(self.profile(),-1)
            calls=[]
            for _ in range(80):
                _,status=stream.feed(self.pcm(45))
                if 'call_id' in status:calls.append(status)
            stream.configure_call(self.profile(),7)
            for volume in [45]*6+[5]*10:
                _,status=stream.feed(self.pcm(volume))
                if 'call_id' in status:calls.append(status)
            self.assertEqual(calls,[])
