#!/usr/bin/env python3
"""Trim trailing silence from a PCM16 WAV while preserving its natural tail."""

from __future__ import annotations

import argparse
import wave
from pathlib import Path

import numpy as np


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--threshold-db", type=float, default=-60.0)
    parser.add_argument("--tail-padding-seconds", type=float, default=0.05)
    parser.add_argument("--fade-out-seconds", type=float, default=0.04)
    args = parser.parse_args()

    with wave.open(str(args.input), "rb") as source:
        channels = source.getnchannels()
        sample_width = source.getsampwidth()
        sample_rate = source.getframerate()
        frame_count = source.getnframes()
        compression_type = source.getcomptype()
        if sample_width != 2 or compression_type != "NONE":
            raise ValueError("Expected an uncompressed 16-bit PCM WAV")
        samples = np.frombuffer(source.readframes(frame_count), dtype="<i2").reshape(
            -1, channels
        )

    normalized = samples.astype(np.float64) / 32768.0
    amplitude = np.max(np.abs(normalized), axis=1)
    threshold = 10.0 ** (args.threshold_db / 20.0)
    audible_frames = np.flatnonzero(amplitude > threshold)
    if audible_frames.size == 0:
        raise ValueError("The WAV contains no samples above the silence threshold")

    padding_frames = round(args.tail_padding_seconds * sample_rate)
    trim_frame = min(len(normalized), int(audible_frames[-1]) + 1 + padding_frames)
    trimmed = normalized[:trim_frame].copy()

    fade_frames = min(round(args.fade_out_seconds * sample_rate), len(trimmed))
    if fade_frames > 0:
        fade = np.linspace(1.0, 0.0, fade_frames, endpoint=True)[:, None]
        trimmed[-fade_frames:] *= fade

    output_pcm = np.clip(np.round(trimmed * 32767.0), -32768, 32767).astype("<i2")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(args.output), "wb") as destination:
        destination.setnchannels(channels)
        destination.setsampwidth(sample_width)
        destination.setframerate(sample_rate)
        destination.writeframes(output_pcm.tobytes())

    original_seconds = frame_count / sample_rate
    trimmed_seconds = len(trimmed) / sample_rate
    print(f"original_duration={original_seconds:.3f}s")
    print(f"trimmed_duration={trimmed_seconds:.3f}s")
    print(f"removed_duration={original_seconds - trimmed_seconds:.3f}s")
    print(f"threshold={args.threshold_db:.1f} dBFS")
    print(f"wrote={args.output}")


if __name__ == "__main__":
    main()
