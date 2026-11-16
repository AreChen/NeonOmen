from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


media = Path(__file__).resolve().parents[1] / "Media"
media.mkdir(exist_ok=True)

panel = Image.new("RGBA", (256, 256))
draw = ImageDraw.Draw(panel)
draw.rounded_rectangle((2, 2, 253, 253), radius=12, fill=(9, 15, 23, 248),
                       outline=(55, 75, 91, 255), width=2)
draw.line((16, 3, 240, 3), fill=(103, 181, 203, 145), width=1)
panel.save(media / "Panel.tga")

mask = Image.new("L", (256, 256))
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle((20, 20, 235, 235), radius=18, outline=255, width=5)
mask = mask.filter(ImageFilter.GaussianBlur(12))
glow = Image.new("RGBA", (256, 256), (255, 255, 255, 0))
glow.putalpha(mask)
glow.save(media / "Glow.tga")

# A neutral, tintable pill with a subtle highlight and transparent corners.
bar_mask = Image.new("L", (128, 32))
ImageDraw.Draw(bar_mask).rounded_rectangle((0, 0, 127, 31), radius=10, fill=255)
bar = Image.new("RGBA", (128, 32))
pixels = bar.load()
for y in range(32):
    level = int(255 - 70 * (y / 31))
    for x in range(128):
        pixels[x, y] = (level, level, level, bar_mask.getpixel((x, y)))
bar.save(media / "NeonBar.tga")
