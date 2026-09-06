#!/usr/bin/env python3
"""Create a technically seamless HOME music loop and a short seam preview."""

from __future__ import annotations

import argparse
import math
import wave
from pathlib import Path

import numpy as np


def read_pcm16_wav(path: Path) -> tuple[np.ndarray, int]:
    with wave.open(str(path), "rb") as source:
        if source.getsampwidth() != 2:
            raise ValueError("Expected a 16-bit PCM WAV")
        channel_count = source.getnchannels()
        sample_rate = source.getframerate()
        samples = np.frombuffer(
            source.readframes(source.getnframes()), dtype="<i2"
        ).reshape(-1, channel_count)
    return samples.astype(np.float64) / 32768.0, sample_rate


def write_pcm16_wav(path: Path, samples: np.ndarray, sample_rate: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.clip(np.round(samples * 32767.0), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as destination:
        destination.setnchannels(pcm.shape[1])
        destination.setsampwidth(2)
        destination.setframerate(sample_rate)
        destination.writeframes(pcm.tobytes())


def dbfs(value: float) -> float:
    return 20.0 * math.log10(max(value, 1.0e-12))


def make_loop(samples: np.ndarray, sample_rate: int, crossfade_seconds: float) -> np.ndarray:
    crossfade_frames = round(crossfade_seconds * sample_rate)
    if crossfade_frames <= 0 or crossfade_frames * 2 >= len(samples):
        raise ValueError("Crossfade duration is not valid for this track")

    # Start playback after the intro. During the final crossfade, blend the
    # original tail into that omitted intro. The final output sample therefore
    # continues directly into the first output sample when playback wraps.
    loop = samples[crossfade_frames:].copy()
    tail = samples[-crossfade_frames:]
    intro = samples[:crossfade_frames]
    phase = np.linspace(0.0, math.pi / 2.0, crossfade_frames, endpoint=True)
    tail_gain = np.cos(phase)[:, None]
    intro_gain = np.sin(phase)[:, None]
    loop[-crossfade_frames:] = tail * tail_gain + intro * intro_gain

    # Preserve one decibel of peak headroom in case the equal-power overlap
    # combines two locally loud moments.
    peak = float(np.max(np.abs(loop)))
    target_peak = 10.0 ** (-1.0 / 20.0)
    if peak > target_peak:
        loop *= target_peak / peak
    return loop


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("seam_preview", type=Path)
    parser.add_argument("--crossfade-seconds", type=float, default=4.0)
    parser.add_argument("--preview-side-seconds", type=float, default=6.0)
    args = parser.parse_args()

    samples, sample_rate = read_pcm16_wav(args.input)
    loop = make_loop(samples, sample_rate, args.crossfade_seconds)
    preview_side_frames = round(args.preview_side_seconds * sample_rate)
    seam_preview = np.concatenate(
        (loop[-preview_side_frames:], loop[:preview_side_frames]), axis=0
    )

    write_pcm16_wav(args.output, loop, sample_rate)
    write_pcm16_wav(args.seam_preview, seam_preview, sample_rate)

    endpoint_step = float(np.max(np.abs(loop[-1] - loop[0])))
    peak = float(np.max(np.abs(loop)))
    rms = math.sqrt(float(np.mean(loop * loop)))
    print(f"loop_duration={len(loop) / sample_rate:.3f}s")
    print(f"peak={dbfs(peak):.2f} dBFS rms={dbfs(rms):.2f} dBFS")
    print(f"endpoint_step={dbfs(endpoint_step):.2f} dBFS")
    print(f"wrote={args.output}")
    print(f"wrote={args.seam_preview}")


if __name__ == "__main__":
    main()
