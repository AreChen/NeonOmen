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
