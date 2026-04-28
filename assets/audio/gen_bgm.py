"""Generate loopable BGM for 3 game modes."""
import numpy as np
import struct
import wave
import os

SR = 44100

def write_wav(path, data, sr=SR):
    data = np.clip(data, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(path, 'w') as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(sr)
        stereo = np.stack([pcm, pcm], axis=1).flatten()
        f.writeframes(stereo.tobytes())

def sine(freq, dur, sr=SR):
    t = np.linspace(0, dur, int(sr * dur), endpoint=False)
    return np.sin(2 * np.pi * freq * t)

def adsr(signal, sr=SR, attack=0.01, decay=0.05, sustain=0.7, release=0.1):
    n = len(signal)
    env = np.ones(n) * sustain
    a = int(attack * sr)
    d = int(decay * sr)
    r = int(release * sr)
    if a > 0:
        env[:a] = np.linspace(0, 1, a)
    if d > 0:
        env[a:a+d] = np.linspace(1, sustain, d)
    if r > 0 and r <= n:
        env[n-r:] = np.linspace(sustain, 0, r)
    return signal * env

def note(freq, dur, amp=0.3, sr=SR, attack=0.01, decay=0.05, sustain=0.7, release=0.08):
    sig = sine(freq, dur, sr) * amp
    # Add harmonics for richer sound
    if freq > 0:
        sig += sine(freq * 2, dur, sr) * amp * 0.3
        sig += sine(freq * 3, dur, sr) * amp * 0.1
    return adsr(sig, sr, attack, decay, sustain, release)

def rest(dur, sr=SR):
    return np.zeros(int(sr * dur))

def seq(notes_list):
    return np.concatenate(notes_list)

def loop(sig, n):
    return np.tile(sig, n)

# ── Easy BGM ── C pentatonic, gentle, 90 BPM ─────────────────────────────
# C4=261.63 D4=293.66 E4=329.63 G4=392.00 A4=440.00 C5=523.25
def make_easy():
    bpm = 90
    q = 60 / bpm  # quarter note duration

    melody_freqs = [
        (523.25, 0.5), (440.00, 0.5), (392.00, 0.5), (329.63, 0.5),
        (392.00, 0.25), (440.00, 0.25), (523.25, 1.0),
        (440.00, 0.5), (523.25, 0.5), (587.33, 0.5), (523.25, 0.5),
        (440.00, 0.75), (392.00, 0.25), (329.63, 1.0),
    ]
    melody = seq([note(f, d * q, amp=0.35, attack=0.02, release=0.12) for f, d in melody_freqs])

    bass_freqs = [
        (130.81, 2.0), (146.83, 2.0),
        (164.81, 2.0), (130.81, 2.0),
    ]
    bass = seq([note(f, d * q, amp=0.18, attack=0.04, decay=0.1, sustain=0.5, release=0.15) for f, d in bass_freqs])

    # pad bass to melody length
    if len(bass) < len(melody):
        bass = np.concatenate([bass, np.zeros(len(melody) - len(bass))])
    else:
        bass = bass[:len(melody)]

    # gentle pad chord (Cmaj)
    pad_dur = len(melody) / SR
    pad = (sine(261.63, pad_dur) * 0.08 +
           sine(329.63, pad_dur) * 0.06 +
           sine(392.00, pad_dur) * 0.05)
    pad = adsr(pad, attack=0.5, decay=0.2, sustain=0.6, release=0.5)

    # percussion: soft hi-hat
    def hihat(dur):
        n = int(SR * dur)
        noise = np.random.randn(n) * 0.06
        env = np.exp(-np.linspace(0, 10, n))
        return noise * env

    hat_pattern = seq([hihat(0.25 * q)] * 32)
    if len(hat_pattern) < len(melody):
        hat_pattern = np.concatenate([hat_pattern, np.zeros(len(melody) - len(hat_pattern))])
    else:
        hat_pattern = hat_pattern[:len(melody)]

    mix = melody + bass + pad[:len(melody)] + hat_pattern
    # loop 2 times
    return loop(mix / np.max(np.abs(mix) + 1e-6) * 0.85, 1)

# ── Normal BGM ── Japanese Yo scale, 110 BPM ─────────────────────────────
# D4=293.66 F4=349.23 G4=392.00 A4=440.00 C5=523.25 D5=587.33
def make_normal():
    bpm = 110
    q = 60 / bpm

    melody_freqs = [
        (440.00, 0.5), (392.00, 0.25), (349.23, 0.25),
        (392.00, 0.5), (440.00, 0.5),
        (523.25, 0.5), (440.00, 0.5),
        (392.00, 1.0),
        (349.23, 0.5), (392.00, 0.25), (440.00, 0.25),
        (523.25, 0.5), (587.33, 0.5),
        (523.25, 0.5), (440.00, 0.5),
        (392.00, 1.0),
    ]
    melody = seq([note(f, d * q, amp=0.32, attack=0.015, release=0.10) for f, d in melody_freqs])

    bass_freqs = [
        (146.83, 1.0), (130.81, 1.0), (87.31, 2.0),
        (110.00, 1.0), (130.81, 1.0), (146.83, 2.0),
    ]
    bass = seq([note(f, d * q, amp=0.20, attack=0.04, decay=0.12, sustain=0.5, release=0.12) for f, d in bass_freqs])
    if len(bass) < len(melody):
        bass = np.concatenate([bass, np.zeros(len(melody) - len(bass))])
    else:
        bass = bass[:len(melody)]

    # tremolo counter-melody
    counter_freqs = [
        (293.66, 0.5), (0, 0.5), (329.63, 0.5), (0, 0.5),
        (349.23, 0.5), (0, 0.5), (329.63, 0.5), (0, 0.5),
        (293.66, 0.5), (0, 0.5), (261.63, 0.5), (0, 0.5),
        (246.94, 0.5), (0, 0.5), (293.66, 0.5), (0, 0.5),
    ]
    counter = seq([note(f, d * q, amp=0.18 if f > 0 else 0, attack=0.02, release=0.08) if f > 0 else rest(d * q) for f, d in counter_freqs])
    if len(counter) < len(melody):
        counter = np.concatenate([counter, np.zeros(len(melody) - len(counter))])
    else:
        counter = counter[:len(melody)]

    def kick(dur):
        n = int(SR * dur)
        t = np.linspace(0, dur, n)
        freq = 80 * np.exp(-t * 20)
        sig = np.sin(2 * np.pi * np.cumsum(freq) / SR) * 0.35
        env = np.exp(-t * 15)
        return sig * env

    def snare(dur):
        n = int(SR * dur)
        t = np.linspace(0, dur, n)
        noise = np.random.randn(n) * 0.18
        tone = np.sin(2 * np.pi * 200 * t) * 0.12
        env = np.exp(-t * 20)
        return (noise + tone) * env

    beat_dur = q
    beat = seq([kick(beat_dur), rest(beat_dur), snare(beat_dur), rest(beat_dur)] * 8)
    if len(beat) < len(melody):
        beat = np.concatenate([beat, np.zeros(len(melody) - len(beat))])
    else:
        beat = beat[:len(melody)]

    mix = melody + bass + counter + beat
    return loop(mix / np.max(np.abs(mix) + 1e-6) * 0.85, 1)

# ── Oni BGM ── Dark minor, intense, 135 BPM ──────────────────────────────
# A3=220 C4=261.63 D4=293.66 Eb4=311.13 F4=349.23 G4=392.00
def make_oni():
    bpm = 135
    q = 60 / bpm

    melody_freqs = [
        (440.00, 0.25), (0, 0.25), (523.25, 0.25), (0, 0.25),
        (622.25, 0.5), (587.33, 0.25), (0, 0.25),
        (523.25, 0.5), (440.00, 0.5),
        (415.30, 1.0),
        (440.00, 0.25), (0, 0.25), (466.16, 0.25), (0, 0.25),
        (440.00, 0.5), (415.30, 0.25), (0, 0.25),
        (392.00, 0.5), (349.23, 0.5),
        (329.63, 1.0),
    ]
    melody = seq([
        note(f, d * q, amp=0.38, attack=0.005, decay=0.04, sustain=0.65, release=0.05) if f > 0
        else rest(d * q) for f, d in melody_freqs
    ])

    bass_freqs = [
        (110.00, 0.5), (0, 0.25), (110.00, 0.25),
        (110.00, 0.5), (116.54, 0.5),
        (110.00, 0.5), (0, 0.25), (110.00, 0.25),
        (103.83, 1.0),
        (98.00, 0.5), (0, 0.25), (98.00, 0.25),
        (103.83, 0.5), (110.00, 0.5),
        (98.00, 0.5), (87.31, 0.5),
        (110.00, 1.0),
    ]
    bass = seq([
        note(f, d * q, amp=0.28, attack=0.01, decay=0.06, sustain=0.55, release=0.06) if f > 0
        else rest(d * q) for f, d in bass_freqs
    ])
    if len(bass) < len(melody):
        bass = np.concatenate([bass, np.zeros(len(melody) - len(bass))])
    else:
        bass = bass[:len(melody)]

    # Distorted power chord stabs
    def power_chord(root, dur):
        fifth = root * 1.5
        n = int(SR * dur)
        sig = (sine(root, dur) * 0.25 +
               sine(fifth, dur) * 0.18 +
               sine(root * 2, dur) * 0.12)
        env = adsr(sig, attack=0.005, decay=0.1, sustain=0.4, release=0.05)
        # soft clip for grit
        return np.tanh(env * 3) * 0.4

    chord_pattern = [
        (110.00, 0.25), (0, 0.25), (110.00, 0.25), (0, 0.25),
        (116.54, 0.25), (0, 0.25), (110.00, 0.25), (0, 0.25),
    ] * 5
    chords = seq([power_chord(f, d * q) if f > 0 else rest(d * q) for f, d in chord_pattern])
    if len(chords) < len(melody):
        chords = np.concatenate([chords, np.zeros(len(melody) - len(chords))])
    else:
        chords = chords[:len(melody)]

    def kick(dur):
        n = int(SR * dur)
        t = np.linspace(0, dur, n)
        freq = 120 * np.exp(-t * 30)
        sig = np.sin(2 * np.pi * np.cumsum(freq) / SR) * 0.45
        env = np.exp(-t * 25)
        return sig * env

    def snare(dur):
        n = int(SR * dur)
        t = np.linspace(0, dur, n)
        noise = np.random.randn(n) * 0.25
        tone = np.sin(2 * np.pi * 250 * t) * 0.15
        env = np.exp(-t * 25)
        return (noise + tone) * env

    def hihat(dur, amp=0.12):
        n = int(SR * dur)
        noise = np.random.randn(n) * amp
        env = np.exp(-np.linspace(0, 15, n))
        return noise * env

    bd = q
    beat = seq([
        kick(bd), hihat(bd), kick(bd * 0.5), rest(bd * 0.5),
        snare(bd), hihat(bd), kick(bd * 0.5), rest(bd * 0.5),
    ] * 10)
    if len(beat) < len(melody):
        beat = np.concatenate([beat, np.zeros(len(melody) - len(beat))])
    else:
        beat = beat[:len(melody)]

    mix = melody + bass + chords + beat
    return loop(mix / np.max(np.abs(mix) + 1e-6) * 0.82, 2)

out_dir = os.path.dirname(os.path.abspath(__file__))

print("Generating bgm_easy.wav ...")
write_wav(os.path.join(out_dir, "bgm_easy.wav"), make_easy())
print("Generating bgm_normal.wav ...")
write_wav(os.path.join(out_dir, "bgm_normal.wav"), make_normal())
print("Generating bgm_oni.wav ...")
write_wav(os.path.join(out_dir, "bgm_oni.wav"), make_oni())
print("Done!")
