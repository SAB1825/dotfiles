# Third-party notices

The plugin's own code is GPL-3.0 (see `LICENSE`), matching the plasmoid it was
ported from. The bundled fonts are covered separately, as recorded here.

## Poppins — `fonts/Poppins.ttf`

- Designers: Indian Type Foundry, Jonny Pinhorn
- License: SIL Open Font License 1.1 — full text in `fonts/OFL.txt`
- Source: <https://fonts.google.com/specimen/Poppins>

The OFL permits redistribution, so this file is tracked in git and ships with the
plugin.

## Anurati — `fonts/Anurati.otf`

- Designer: Emmeran Richard
- Source: <https://www.behance.net/gallery/40672099/ANURATI-Free-Font>
- Terms: distributed by the designer as **free for personal use**. Commercial use
  requires permission from the designer.

The file is included in this repository for convenience, unmodified, the same way
the upstream plasmoid (`Prayag2/kde_modernclock`) packages it. To be explicit
about what that does and does not mean:

- The plugin's GPL-3.0 license covers the **code only**. It does not, and cannot,
  relicense this font. The font remains under the designer's personal-use terms
  wherever it travels.
- Inclusion here is **not** backed by an explicit redistribution grant from the
  designer. It follows the common packaging practice for this font (Behance
  download, the upstream plasmoid, the KDE Store build), nothing stronger.
- If you use this plugin in any commercial context, obtain permission from the
  designer or replace the Day Font via the plugin's font picker.
- If the designer objects to the font's inclusion, it will be removed; the plugin
  degrades gracefully without it (DMS UI font fallback, or any installed font via
  the picker).

Two things about the font binary itself, because both are easy to misread:

- Its `name` table contains **no license fields at all** (no nameID 13 "License
  Description", no nameID 14 "License URL"). The personal-use terms come from the
  designer's Behance posting, not from the file.
- Its copyright string reads `Copyright 2016 Adobe Systems Incorporated. All
  rights reserved.` This is a leftover default from the FontLab template it was
  built with. Anurati is **not** an Adobe font; the `Designer` field is the
  accurate one.
