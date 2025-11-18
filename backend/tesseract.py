import pytesseract
from PIL import Image
import sys

def extract_text(image_path):
    image = Image.open(image_path)
    text = pytesseract.image_to_string(image)
    return text

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: No image path provided", file=sys.stderr)
        sys.exit(1)

    image_path = sys.argv[1]
    try:
        text = extract_text(image_path)
        print(text)
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)