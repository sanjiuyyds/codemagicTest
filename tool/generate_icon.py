"""Generate a 1024px iOS app icon approximating liquid glass."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "native_ios" / "AppIcon.appiconset" / "AppIcon.png"


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c0: tuple[int, int, int], c1: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(lerp(c0[0], c1[0], t)),
        int(lerp(c0[1], c1[1], t)),
        int(lerp(c0[2], c1[2], t)),
    )


def main() -> None:
    img = Image.new("RGB", (SIZE, SIZE), (5, 8, 22))
    px = img.load()
    cx = cy = SIZE / 2
    for y in range(SIZE):
        for x in range(SIZE):
            dx = (x - cx) / SIZE
            dy = (y - cy) / SIZE
            r = math.sqrt(dx * dx + dy * dy)
            t = min(1.0, r * 1.35)
            col = mix((12, 22, 58), (4, 6, 16), t)
            # iridescent wash
            ang = math.atan2(dy, dx)
            wash = 0.12 * (0.5 + 0.5 * math.sin(ang * 2.0 + r * 8.0))
            col = (
                min(255, int(col[0] + 40 * wash)),
                min(255, int(col[1] + 90 * wash)),
                min(255, int(col[2] + 140 * wash)),
            )
            px[x, y] = col

    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")

    blobs = [
        (180, 220, 520, 560, (56, 189, 248, 70)),
        (430, 140, 920, 620, (167, 139, 250, 64)),
        (80, 480, 560, 980, (45, 212, 191, 50)),
        (520, 560, 980, 1000, (96, 165, 250, 40)),
    ]
    for box in blobs:
        layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ImageDraw.Draw(layer, "RGBA").ellipse(box[:4], fill=box[4])
        overlay = Image.alpha_composite(overlay, layer.filter(ImageFilter.GaussianBlur(90)))

    # glass orb
    orb = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(orb, "RGBA")
    r = 310
    box = (cx - r, cy - r, cx + r, cy + r)
    od.ellipse(box, fill=(226, 244, 255, 48), outline=(255, 255, 255, 76), width=3)
    inner = (cx - r + 28, cy - r + 28, cx + r - 28, cy + r - 28)
    od.ellipse(inner, fill=(180, 220, 255, 28))
    # specular
    od.ellipse((cx - 170, cy - 220, cx + 40, cy - 40), fill=(255, 255, 255, 70))
    od.ellipse((cx + 40, cy + 80, cx + 160, cy + 190), fill=(125, 211, 252, 40))
    orb = orb.filter(ImageFilter.GaussianBlur(2))
    overlay = Image.alpha_composite(overlay, orb)

    ring = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring, "RGBA")
    rd.ellipse((cx - 338, cy - 338, cx + 338, cy + 338), outline=(186, 230, 253, 90), width=6)
    overlay = Image.alpha_composite(overlay, ring.filter(ImageFilter.GaussianBlur(1)))

    out = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT, "PNG")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
