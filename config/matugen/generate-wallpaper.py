import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET


def recolor_special_folders(places: Path) -> None:
    adwaita_places = Path("/usr/share/icons/Adwaita/scalable/places")
    folder = ET.parse(places / "folder.svg")
    background, foreground = (path.attrib["fill"] for path in folder.getroot())
    palette = {
        "#438de6": background,
        "#62a0ea": background,
        "#a4caee": foreground,
        "#afd4ff": foreground,
        "#c0d5ea": foreground,
    }
    adwaita_colors = re.compile("|".join(palette), re.IGNORECASE)
    icons = sorted(adwaita_places.glob("folder-*.svg"))
    icons.extend(adwaita_places / name for name in ("user-home.svg", "user-desktop.svg"))
    for source in icons:
        if source.is_file():
            svg = adwaita_colors.sub(
                lambda match: palette[match[0].lower()], source.read_text()
            )
            (places / source.name).write_text(svg)
    # GTK watches the theme directory for icon changes.
    places.parent.parent.touch()


def generate_colors(state_path: Path) -> None:
    config = Path(__file__).with_name("config.toml")
    theme_dir = config.parent / "generated/icons/Matugen-Folders"
    theme_dir.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(config.parent / "templates/index.theme", theme_dir / "index.theme")
    wallpaper = json.loads(state_path.read_text())
    while True:
        subprocess.run(
            ["matugen", "image", "--config", str(config),
             "--source-color-index", "0", "--", wallpaper],
            check=True,
        )
        latest = json.loads(state_path.read_text())
        if latest == wallpaper:
            recolor_special_folders(theme_dir / "scalable/places")
            return
        wallpaper = latest


if __name__ == "__main__":
    generate_colors(Path(sys.argv[1]))
