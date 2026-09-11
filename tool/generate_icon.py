"""Generate a 1024px app icon: white background, black XS letters."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "native_ios" / "AppIcon.appiconset" / "AppIcon.png"
FONTS = [
    Path(r"C:\Windows\Fonts\arialbd.ttf"),
    Path(r"C:\Windows\Fonts\segoeuib.ttf"),
    Path(r"C:\Windows\Fonts\calibrib.ttf"),
    Path(r"C:\Windows\Fonts\arial.ttf"),
]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONTS:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def main() -> None:
    img = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    text = "XS"
    font = load_font(520)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (SIZE - tw) / 2 - bbox[0]
    y = (SIZE - th) / 2 - bbox[1] - 12
    draw.text((x, y), text, font=font, fill=(0, 0, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
