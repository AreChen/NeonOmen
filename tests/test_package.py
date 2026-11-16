from pathlib import Path
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def test_release_archive_contains_only_addon_files(tmp_path):
    output = tmp_path / "neon.zip"
    subprocess.run([sys.executable, str(ROOT / "tools" / "package.py"), str(output)], check=True)
    with zipfile.ZipFile(output) as archive:
        names = set(archive.namelist())
        assert "NeonOmenReborn/NeonOmenReborn.toc" in names
        assert "NeonOmenReborn/LICENSE" in names
        assert "NeonOmenReborn/Media/Glow.tga" in names
        assert all(name.startswith("NeonOmenReborn/") for name in names)
        assert not any("backups/" in name or "tests/" in name or ".git/" in name for name in names)
        toc = archive.read("NeonOmenReborn/NeonOmenReborn.toc").decode("utf-8")
        for line in toc.splitlines():
            if line and not line.startswith("#"):
                assert "NeonOmenReborn/" + line.replace("\\", "/") in names
