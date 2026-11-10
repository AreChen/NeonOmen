from pathlib import Path
import runpy
from zipfile import ZipFile

from support import ROOT


def test_installation_package_contains_toc_dependencies_and_no_development_files(tmp_path):
    tool = runpy.run_path(str(ROOT / "tools/package.py"))
    path = tool["package"](tmp_path / "addon.zip")
    with ZipFile(path) as archive:
        entries = set(archive.namelist())
        assert entries == {f"OmenReloadedForever/{p}" for p in tool["RUNTIME_FILES"]}
        toc = archive.read("OmenReloadedForever/OmenReloadedForever.toc").decode()
        for line in toc.splitlines():
            if line and not line.startswith("#"):
                assert f"OmenReloadedForever/{line}" in entries
        assert not any(Path(p).suffix == ".py" for p in entries)
