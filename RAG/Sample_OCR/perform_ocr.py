#!/usr/bin/env python3
"""
perform_ocr.py

This helper script loads the DeepSeek‑OCR model and performs optical character
recognition on a given image file.  The script prints an XML document to
standard output containing the recognized text.

DeepSeek‑OCR is an open vision‑language model specifically designed for
document understanding.  It uses context optical
compression to map large two‑dimensional images into a compact set of vision
tokens, enabling it to handle large scanned documents, receipts, tables, and
multilingual or handwritten content efficiently.

Prerequisites:
  * Install `torch`, `transformers>=4.46.3`, `einops`, `addict`, and
    `flash-attn` as recommended in the official guides.
  * A GPU with sufficient VRAM (DeepSeek‑OCR contains roughly 3B parameters).

Usage:
    python3 perform_ocr.py /path/to/image.png

If the model dependencies are missing or a GPU is not available, the script
falls back to returning a simple XML stub indicating that OCR could not be
performed.
"""

import sys
import os
import json
from typing import Optional

def load_model():
    """Attempt to load the DeepSeek‑OCR model.  Returns a tuple
    (model, tokenizer) or (None, None) if dependencies are missing."""
    try:
        import torch  # type: ignore
        from transformers import AutoModel, AutoTokenizer  # type: ignore
    except ImportError:
        return None, None
    model_name = "deepseek-ai/DeepSeek-OCR"
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        # Ensure the tokenizer has a pad token
        if tokenizer.pad_token is None and tokenizer.eos_token is not None:
            tokenizer.pad_token = tokenizer.eos_token
        model = AutoModel.from_pretrained(
            model_name,
            trust_remote_code=True,
            use_safetensors=True,
            attn_implementation="eager",
        ).to(dtype=torch.bfloat16)
        model = model.eval()
        return model, tokenizer
    except Exception:
        # Could not load the model (e.g. missing GPU or weights)
        return None, None

def run_ocr(model, tokenizer, image_path: str) -> Optional[str]:
    """Run DeepSeek‑OCR on the given image.  Returns a string with the
    recognized text or None on failure."""
    try:
        from PIL import Image  # type: ignore
    except ImportError:
        return None
    # Use the prompt recommended for plain OCR.  Other prompts can return
    # structured output such as Markdown or HTML depending on your needs.
    prompt = "<image>\nFree OCR."
    try:
        # According to DeepSeek‑OCR examples, the infer method is used to
        # process a single image and return results【344464395425472†L157-L208】.
        result = model.infer(
            tokenizer,
            prompt=prompt,
            image_file=image_path,
            output_path=None,
            base_size=1024,
            image_size=640,
            crop_mode=True,
            save_results=False,
            test_compress=True,
        )
        # The model returns a dictionary containing the predicted string at
        # `pred_str` when save_results is False.  Use a default key if not
        # present.
        text = None
        if isinstance(result, dict):
            text = result.get("pred_str") or result.get("text")
        # Some versions of the API return a list of strings.
        if text is None and isinstance(result, (list, tuple)) and len(result) > 0:
            text = result[0]
        return text
    except Exception:
        return None

def emit_xml(text: Optional[str]) -> None:
    """Emit the recognized text wrapped in a simple XML structure."""
    if text is None:
        print("<ocr><error>OCR not available</error></ocr>")
    else:
        # Escape XML special characters
        import xml.sax.saxutils as saxutils
        escaped = saxutils.escape(text)
        print(f"<ocr><text>{escaped}</text></ocr>")

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: perform_ocr.py <image_path>", file=sys.stderr)
        sys.exit(1)
    image_path = sys.argv[1]
    model, tokenizer = load_model()
    if model is None or tokenizer is None:
        emit_xml(None)
        return
    text = run_ocr(model, tokenizer, image_path)
    emit_xml(text)

if __name__ == "__main__":
    main()