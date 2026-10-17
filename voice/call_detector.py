"""Personal, bounded call detection independent of decoder endpoints."""
from array import array
import math


class CallDetector:
    def __init__(self):
        self.profile = {}
        self.serial = 0
        self.reset()

    def configure(self, profile: dict) -> None:
        fields = ('on_rms', 'off_rms', 'min_call_s', 'max_call_s', 'release_s')
        valid = isinstance(profile, dict) and all(
            isinstance(profile.get(k), (float, int)) and not isinstance(profile[k], bool)
            and math.isfinite(profile[k]) and profile[k] > 0 for k in fields)
        valid = valid and profile.get('version') == 1 and isinstance(profile.get('device'), str)
        valid = valid and 0 < profile['off_rms'] < profile['on_rms'] <= 32768
        valid = valid and profile['min_call_s'] < profile['max_call_s'] <= 5 and profile['release_s'] <= 2
        selected = dict(profile) if valid else {}
        if selected != self.profile:
            self.profile = selected
            self.reset()

    def reset(self) -> None:
        self.active = False
        self.duration = self.silent = self.peak = 0.0
        self.opportunity = -1
        self.command = False
        self.too_long = False

    def feed(self, pcm: bytes, opportunity_id: int, has_command: bool) -> dict | None:
        if not self.profile or not pcm:
            return None
        samples = array('h', pcm)
        rms = math.sqrt(sum(x*x for x in samples) / len(samples))
        dt = len(samples) / 16000
        if not self.active:
            if rms < self.profile['on_rms']:
                return None
            self.active = True
            self.serial += 1
        self.command |= has_command
        if rms >= self.profile['off_rms']:
            if self.opportunity < 0 and opportunity_id >= 0:
                self.opportunity = opportunity_id
            self.duration += dt
            self.peak = max(self.peak, rms)
            self.silent = 0.0
            self.too_long |= self.duration > self.profile['max_call_s']
            return None
        self.silent += dt
        if self.silent + 1e-9 < self.profile['release_s']:
            return None
        event = None
        if not self.command and not self.too_long and self.duration + 1e-9 >= self.profile['min_call_s'] and self.opportunity >= 0:
            event = dict(call_id=self.serial, opportunity_id=self.opportunity,
                         peak_rms=self.peak, speech_seconds=self.duration, has_command=False)
        self.reset()
        return event
