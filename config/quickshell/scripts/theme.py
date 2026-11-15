#!/usr/bin/env python3
"""Render SVG wallpapers before passing them to Matugen."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
image, mode, scheme = sys.argv[1:4]
with tempfile.TemporaryDirectory(prefix='phoenix-theme-') as directory:
    if Path(image).suffix.lower() == '.svg':
        rendered = str(Path(directory) / 'wallpaper.png')
        subprocess.run(['magick', image, '-resize', '512x512>', rendered], check=True)
        image = rendered
    subprocess.run(['matugen', '--config', str(root / 'theme/matugen.toml'),
                    '--mode', mode, '--type', scheme, '--source-color-index', '0',
                    'image', image], check=True)
    # Reload Kitty's includes without enabling its remote-control socket.
    subprocess.run(['pkill', '-USR1', '-u', str(os.getuid()), '-x', 'kitty'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
