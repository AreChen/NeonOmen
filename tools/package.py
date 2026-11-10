"""Build the installable addon without repository or development files."""
from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_FILES = (
    "OmenReloadedForever.toc",
    "OmenReloadedForever.lua",
    "Locale.lua",
    "UI/Theme.lua",
    "Bindings.xml",
    "Media/NeonBack.tga",
    "Media/NeonRing.tga",
    "Media/NeonGlow.tga",
    "Media/ThreatGradient.tga",
    "Media/ThreatMask.tga",
    "Media/ThreatGlow.tga",
)


def package(destination=None):
    toc = (ROOT / "OmenReloadedForever.toc").read_text()
    version = re.search(r"^## Version:\s*(\S+)", toc, re.MULTILINE).group(1)
    destination = Path(destination) if destination else ROOT / "dist" / f"NeonOmen-{version}.zip"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(destination, "w", compression=ZIP_DEFLATED) as archive:
        for relative in RUNTIME_FILES:
            archive.write(ROOT / relative, f"OmenReloadedForever/{relative}")
    return destination


if __name__ == "__main__":
    print(package())
