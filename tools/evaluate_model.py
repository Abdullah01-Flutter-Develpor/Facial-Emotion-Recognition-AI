#!/usr/bin/env python3
"""Evaluate the EmoSense AI emotion model on FER-2013.

Reproduces the app's exact preprocessing (lib/ml/emotion_classifier.dart):
grayscale -> 48x48 -> 112x112 with the `image` package's "average"
interpolation -> 3 channels -> ImageNet mean/std, and the app's test-time
augmentation (average of the original and the mirrored image).

Two dataset layouts are supported:

  1. The original Kaggle CSV (fer2013.csv or icml_face_data.csv):
       python tools/evaluate_model.py --csv fer2013.csv --usage PrivateTest

  2. The image-folder version (test/angry/*.png, test/happy/*.png, ...):
       python tools/evaluate_model.py --folder path/to/test

Outputs (in --out, default evaluation_results/):
  metrics.json            overall accuracy, per-class precision/recall/F1
  report.md               the same as a table, ready for the project report
  confusion_matrix.csv    rows = true class, columns = predicted class
  confusion_matrix.png    heat map (needs matplotlib)

Requirements: pip install onnxruntime numpy pillow matplotlib
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from pathlib import Path

import numpy as np

# Model output order (alphabetical, as in the app).
CLASSES = ["angry", "disgust", "fear", "happy", "neutral", "sad", "surprise"]
# Label numbers used in the FER-2013 CSV files.
FER_LABELS = ["angry", "disgust", "fear", "happy", "sad", "surprise", "neutral"]
INPUT_SIZE = 112
SOURCE_SIZE = 48
MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def resize_average(src: np.ndarray, width: int, height: int) -> np.ndarray:
    """Port of copyResize(interpolation: Interpolation.average) from the Dart
    `image` package, so evaluation sees the same pixels as the app."""
    src_h, src_w = src.shape
    dx = src_w / width
    dy = src_h / height
    if dx <= 1 and dy <= 1:
        # Enlarging: every output pixel averages exactly one source pixel.
        ys = (np.arange(height) * dy).astype(int)
        xs = (np.arange(width) * dx).astype(int)
        return src[ys[:, None], xs[None, :]].astype(np.uint8)
    out = np.empty((height, width), dtype=np.float64)
    for y in range(height):
        ay1 = int(y * dy)
        ay2 = int((y + 1) * dy)
        if ay2 == ay1:
            ay2 += 1
        for x in range(width):
            ax1 = int(x * dx)
            ax2 = int((x + 1) * dx)
            if ax2 == ax1:
                ax2 += 1
            out[y, x] = src[ay1:ay2, ax1:ax2].mean()
    # The app stores the result in an 8-bit image, which truncates.
    return np.floor(out).astype(np.uint8)


def preprocess(gray: np.ndarray, flip: bool) -> np.ndarray:
    source = resize_average(gray, SOURCE_SIZE, SOURCE_SIZE) if gray.shape != (
        SOURCE_SIZE,
        SOURCE_SIZE,
    ) else gray.astype(np.uint8)
    resized = resize_average(source, INPUT_SIZE, INPUT_SIZE).astype(np.float32) / 255.0
    if flip:
        resized = resized[:, ::-1]
    tensor = (resized[None, :, :] - MEAN[:, None, None]) / STD[:, None, None]
    return tensor.astype(np.float32)


def softmax(logits: np.ndarray) -> np.ndarray:
    e = np.exp(logits - logits.max(axis=-1, keepdims=True))
    return e / e.sum(axis=-1, keepdims=True)


def load_csv(path: Path, usage: str):
    with path.open(newline="") as handle:
        for raw in csv.DictReader(handle):
            # icml_face_data.csv uses "emotion, Usage, pixels" (with spaces).
            row = {key.strip(): value for key, value in raw.items()}
            if usage and row.get("Usage", "").strip() != usage:
                continue
            pixels = np.array(row["pixels"].split(), dtype=np.uint8).reshape(48, 48)
            yield pixels, CLASSES.index(FER_LABELS[int(row["emotion"])])


def load_folder(path: Path):
    from PIL import Image

    for label, name in enumerate(CLASSES):
        folder = path / name
        if not folder.is_dir():
            print(f"warning: missing class folder {folder}", file=sys.stderr)
            continue
        for file in sorted(folder.iterdir()):
            if file.suffix.lower() not in {".png", ".jpg", ".jpeg", ".bmp"}:
                continue
            gray = np.array(Image.open(file).convert("L"), dtype=np.uint8)
            yield gray, label


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--csv", type=Path, help="fer2013.csv")
    source.add_argument("--folder", type=Path, help="folder with one sub-folder per class")
    parser.add_argument("--usage", default="PrivateTest", help="CSV split: PrivateTest, PublicTest or Training")
    parser.add_argument("--model", type=Path, default=Path(__file__).resolve().parents[1] / "assets/models/emotion_model.onnx")
    parser.add_argument("--out", type=Path, default=Path("evaluation_results"))
    parser.add_argument("--no-flip", action="store_true", help="disable the mirror-image averaging the app uses")
    parser.add_argument("--limit", type=int, default=0, help="evaluate only the first N images (0 = all)")
    args = parser.parse_args()

    import onnxruntime as ort

    session = ort.InferenceSession(str(args.model), providers=["CPUExecutionProvider"])
    samples = load_csv(args.csv, args.usage) if args.csv else load_folder(args.folder)

    confusion = np.zeros((len(CLASSES), len(CLASSES)), dtype=np.int64)
    started = time.perf_counter()
    count = 0
    for gray, label in samples:
        batch = [preprocess(gray, flip=False)]
        if not args.no_flip:
            batch.append(preprocess(gray, flip=True))
        # The exported model has a fixed batch size of 1.
        probabilities = np.mean(
            [softmax(session.run(None, {"input": x[None]})[0][0]) for x in batch], axis=0
        )
        confusion[label, int(probabilities.argmax())] += 1
        count += 1
        if count % 500 == 0:
            print(f"{count} images...", file=sys.stderr)
        if args.limit and count >= args.limit:
            break
    if count == 0:
        print("No images found.", file=sys.stderr)
        return 1
    elapsed = time.perf_counter() - started

    accuracy = float(np.trace(confusion) / confusion.sum())
    per_class = {}
    for i, name in enumerate(CLASSES):
        tp = confusion[i, i]
        predicted = confusion[:, i].sum()
        actual = confusion[i, :].sum()
        precision = float(tp / predicted) if predicted else 0.0
        recall = float(tp / actual) if actual else 0.0
        f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
        per_class[name] = {"precision": precision, "recall": recall, "f1": f1, "support": int(actual)}
    macro_f1 = float(np.mean([v["f1"] for v in per_class.values()]))

    args.out.mkdir(parents=True, exist_ok=True)
    metrics = {
        "images": count,
        "accuracy": accuracy,
        "macro_f1": macro_f1,
        "test_time_flip": not args.no_flip,
        "split": args.usage if args.csv else str(args.folder),
        "seconds": round(elapsed, 1),
        "per_class": per_class,
    }
    (args.out / "metrics.json").write_text(json.dumps(metrics, indent=2))

    with (args.out / "confusion_matrix.csv").open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["true \\ predicted", *CLASSES])
        for i, name in enumerate(CLASSES):
            writer.writerow([name, *confusion[i].tolist()])

    lines = [
        "# Emotion model evaluation",
        "",
        f"Images: {count}  ",
        f"Overall accuracy: **{accuracy * 100:.2f}%**  ",
        f"Macro F1: {macro_f1:.3f}  ",
        f"Mirror averaging (as in the app): {'on' if not args.no_flip else 'off'}",
        "",
        "| Class | Precision | Recall | F1 | Images |",
        "| --- | --- | --- | --- | --- |",
    ]
    for name, v in per_class.items():
        lines.append(f"| {name} | {v['precision']:.3f} | {v['recall']:.3f} | {v['f1']:.3f} | {v['support']} |")
    (args.out / "report.md").write_text("\n".join(lines) + "\n")

    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        normalised = confusion / np.maximum(confusion.sum(axis=1, keepdims=True), 1)
        fig, ax = plt.subplots(figsize=(7, 6))
        im = ax.imshow(normalised, cmap="Blues", vmin=0, vmax=1)
        ax.set_xticks(range(len(CLASSES)), CLASSES, rotation=45, ha="right")
        ax.set_yticks(range(len(CLASSES)), CLASSES)
        ax.set_xlabel("Predicted")
        ax.set_ylabel("True")
        ax.set_title(f"Confusion matrix (accuracy {accuracy * 100:.1f}%)")
        for i in range(len(CLASSES)):
            for j in range(len(CLASSES)):
                ax.text(j, i, f"{normalised[i, j]:.2f}", ha="center", va="center",
                        color="white" if normalised[i, j] > 0.5 else "black", fontsize=8)
        fig.colorbar(im, ax=ax, fraction=0.046)
        fig.tight_layout()
        fig.savefig(args.out / "confusion_matrix.png", dpi=150)
    except ImportError:
        print("matplotlib not installed: skipped confusion_matrix.png", file=sys.stderr)

    print(f"Accuracy {accuracy * 100:.2f}% on {count} images. Results in {args.out}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
