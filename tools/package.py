"""Build an installable archive without local backups or development files."""
from pathlib import Path
import argparse
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ADDON = "NeonOmenReborn"
FILES = (
    "NeonOmenReborn.toc", "Bindings.xml", "Core.lua", "Meter.lua", "Settings.lua", "Minimap.lua",
    "LICENSE", "README.md", "README.zh-CN.md", "Media/Panel.tga", "Media/Glow.tga", "Media/NeonBar.tga",
)


def build(output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name in FILES:
            archive.write(ROOT / name, f"{ADDON}/{name}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    build(parser.parse_args().output)
