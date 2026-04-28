"""Generate win sound effect: シャキーン"""
import numpy as np
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

def make_shakiin():
    dur = 1.5
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # ── 金属打撃音（シャ） ──
    # 高周波ノイズ + フィルタで金属感
    noise = np.random.randn(n) * 0.5
    # 急激な減衰
    hit_env = np.exp(-t * 18)
    metal_hit = noise * hit_env * 0.45

    # ── 上昇音（キーン） ──
    # グリッサンド: 周波数が上昇するサイン波
    freq_start = 400
    freq_end = 2200
    freq = freq_start + (freq_end - freq_start) * (1 - np.exp(-t * 5))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    glide = np.sin(phase)

    # ── 倍音を重ねてキラキラ感 ──
    sparkle = (
        np.sin(phase * 2) * 0.4 +
        np.sin(phase * 3) * 0.2 +
        np.sin(phase * 4) * 0.1
    )

    # キーン部分のエンベロープ: 素早くアタック → ゆっくり減衰
    keen_env = np.exp(-t * 5.0) * (1 - np.exp(-t * 100))
    keen = (glide + sparkle) * keen_env * 0.55

    # ── 余韻のリング ──
    ring_freq = 1600
    ring = np.sin(2 * np.pi * ring_freq * t) * np.exp(-t * 9) * 0.25

    # ── ミックス ──
    mix = metal_hit + keen + ring
    peak = np.max(np.abs(mix))
    return mix / peak * 0.88

def make_gameover():
    dur = 2.5
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # ── ドボン：重い打撃 ──
    hit_dur = 0.3
    nt = int(hit_dur * SR)
    th = np.linspace(0, hit_dur, nt, endpoint=False)
    # 急速に下降する周波数（牌を卓に叩きつける感）
    body_freq = 180 * np.exp(-th * 30)
    body = np.sin(2 * np.pi * np.cumsum(body_freq) / SR)
    body += np.sin(2 * np.pi * np.cumsum(body_freq * 2) / SR) * 0.4
    hit_noise = np.random.randn(nt) * 0.35
    hit_env = np.exp(-th * 22)
    hit = (body + hit_noise) * hit_env * 0.75
    hit_sig = np.zeros(n)
    hit_sig[:nt] = hit

    # ── 長い低音余韻（ボーン） ──
    resonance = (
        np.sin(2 * np.pi * 65 * t) * 0.40 +
        np.sin(2 * np.pi * 98 * t) * 0.25 +
        np.sin(2 * np.pi * 130 * t) * 0.15
    )
    res_env = np.exp(-t * 1.2) * (1 - np.exp(-t * 40))
    res_sig = resonance * res_env * 0.6

    # ── ざわっとしたノイズ層（崩れる感） ──
    rumble = np.random.randn(n) * np.exp(-t * 3.5) * 0.12

    mix = hit_sig + res_sig + rumble
    peak = np.max(np.abs(mix))
    return mix / peak * 0.88


def make_tenpai():
    # 短い2音アルペジオ + 余韻 （緊張感・警戒感）
    dur = 0.8
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    def tone(freq, start, length, amp=0.55):
        sig = np.zeros(n)
        i = int(start * SR)
        nt = int(length * SR)
        if i + nt > n:
            nt = n - i
        tt = np.linspace(0, length, nt, endpoint=False)
        wave = (np.sin(2 * np.pi * freq * tt) * 0.7 +
                np.sin(2 * np.pi * freq * 2 * tt) * 0.2 +
                np.sin(2 * np.pi * freq * 3 * tt) * 0.1)
        env = np.exp(-tt * 6) * (1 - np.exp(-tt * 80))
        sig[i:i+nt] = wave * env * amp
        return sig

    # ド（低）→ ソ（高）の2音で「リーチ！」感
    note1 = tone(440.0, start=0.0, length=0.25, amp=0.55)   # A4
    note2 = tone(659.3, start=0.22, length=0.45, amp=0.65)  # E5（緊張音）

    # 木琴風の硬い打撃感
    def click(t_offset, freq=1200):
        sig = np.zeros(n)
        i = int(t_offset * SR)
        nt = int(0.06 * SR)
        if i + nt > n:
            nt = n - i
        tt = np.linspace(0, 0.06, nt, endpoint=False)
        sig[i:i+nt] = np.sin(2 * np.pi * freq * tt) * np.exp(-tt * 60) * 0.35
        return sig

    c1 = click(0.0, freq=1100)
    c2 = click(0.22, freq=1400)

    mix = note1 + note2 + c1 + c2
    peak = np.max(np.abs(mix))
    return mix / peak * 0.85


def make_meld():
    # 短い「ポン！」＋明るいチャイム（0.4秒）
    dur = 0.4
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # 木の板を叩くような「コン」打撃
    hit_freq = 520
    hit = np.sin(2 * np.pi * hit_freq * t) * 0.5
    hit += np.sin(2 * np.pi * hit_freq * 2.1 * t) * 0.2  # 非整数倍音で木質感
    hit_env = np.exp(-t * 28)
    hit_sig = hit * hit_env

    # 明るい小さなチャイム（余韻）
    chime = (np.sin(2 * np.pi * 880 * t) * 0.30 +
             np.sin(2 * np.pi * 1320 * t) * 0.15)
    chime_env = np.exp(-t * 8) * (1 - np.exp(-t * 120))
    chime_sig = chime * chime_env

    mix = hit_sig + chime_sig
    peak = np.max(np.abs(mix))
    return mix / peak * 0.82


out_dir = os.path.dirname(os.path.abspath(__file__))
print("Generating sfx_win.wav ...")
write_wav(os.path.join(out_dir, "sfx_win.wav"), make_shakiin())
print("Generating sfx_gameover.wav ...")
write_wav(os.path.join(out_dir, "sfx_gameover.wav"), make_gameover())
print("Generating sfx_tenpai.wav ...")
write_wav(os.path.join(out_dir, "sfx_tenpai.wav"), make_tenpai())
print("Generating sfx_meld.wav ...")
write_wav(os.path.join(out_dir, "sfx_meld.wav"), make_meld())
print("Done!")
