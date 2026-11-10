from pathlib import Path
import re
import runpy
from zipfile import ZipFile

from support import ROOT


def test_installation_package_contains_toc_dependencies_and_no_development_files(tmp_path):
    tool = runpy.run_path(str(ROOT / "tools/package.py"))
    path = tool["package"](tmp_path / "addon.zip")
    with ZipFile(path) as archive:
        entries = set(archive.namelist())
        assert entries == {f"NeonOmen/{p}" for p in tool["RUNTIME_FILES"]}
        toc = archive.read("NeonOmen/NeonOmen.toc").decode()
        for line in toc.splitlines():
            if line and not line.startswith("#"):
                assert f"NeonOmen/{line}" in entries
        assert not any(Path(p).suffix == ".py" for p in entries)


def test_packaged_media_references_match_the_installation_directory(tmp_path):
    tool = runpy.run_path(str(ROOT / "tools/package.py"))
    with ZipFile(tool["package"](tmp_path / "addon.zip")) as archive:
        references = []
        for entry in archive.namelist():
            if entry.endswith(".lua"):
                references.extend(re.findall(r'Interface\\\\AddOns\\\\([^\\]+)\\\\', archive.read(entry).decode()))
        assert references and set(references) == {"NeonOmen"}
