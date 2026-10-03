#!/usr/bin/env python3
"""Second pass: ICU plurals and leftover French accent fixes."""

from __future__ import annotations

import json
import re
from pathlib import Path

ARB = Path(__file__).resolve().parents[1] / "lib" / "l10n" / "app_fr.arb"

FIXES = {
    "folderItemCount": "{count, plural, =1{1 élément} other{{count} éléments}}",
    "storageAllFilesAccessDialogMessage": (
        "La suppression ou le déplacement d'éléments entre albums sur Android 11+ "
        "nécessite l'accès à tous les fichiers dans les paramètres système."
    ),
    "snackbarMovedToTrash": (
        "{count, plural, =1{1 élément déplacé} other{{count} éléments déplacés}} "
        "vers la corbeille"
    ),
    "snackbarMovedItems": (
        "{moved, plural, =1{1 élément déplacé} other{{moved} éléments déplacés}}"
    ),
    "snackbarAlbumCreatedAndMoved": (
        'Album "{albumName}" créé et '
        "{count, plural, =1{1 élément déplacé} other{{count} éléments déplacés}}"
    ),
    "tooltipSetAlbumCover": "Définir comme couverture",
    "selectionSetAsWallpaper": "Définir comme fond d'écran",
    "snackbarSharedItems": (
        "{count, plural, =1{1 élément partagé} other{{count} éléments partagés}}"
    ),
    "snackbarWallpaperFailed": "Impossible de définir le fond d'écran",
    "wallpaperConfirmTitle": "Définir comme fond d'écran ?",
    "wallpaperConfirmMessage": (
        "Cette image sera définie comme fond d'écran de l'écran d'accueil."
    ),
    "wallpaperConfirmAction": "Définir",
    "snackbarRestoredItems": (
        "{count, plural, =1{1 élément restauré} other{{count} éléments restaurés}}"
    ),
    "snackbarPermanentlyDeleted": (
        "{count, plural, =1{1 élément supprimé} other{{count} éléments supprimés}} "
        "définitivement"
    ),
    "settingsWidgetsHelpBody": (
        "Appuyez longuement sur l'écran d'accueil, choisissez Widgets, puis "
        "Social Gallery. Configurez l'album, l'intervalle et le rafraîchissement "
        "au déverrouillage."
    ),
    "widgetConfigRefreshOnUnlock": "Changer au déverrouillage",
    "compressionResult": "{done} images compressées, {mb} Mo économisés",
    "duplicateReviewSubtitle": (
        "La meilleure est présélectionnée. Appuyez sur les éléments pour "
        "modifier ce qui sera supprimé."
    ),
    "backupStatusUpToDate": "À jour",
    "notificationDuplicateScanFailedBody": (
        "Impossible de terminer l'analyse. Ouvrez Doublons pour réessayer."
    ),
}

GLOBAL_REPL = [
    ("Definir", "Définir"),
    ("definir", "définir"),
    ("definie", "définie"),
    ("deplacement", "déplacement"),
    ("deverrouillage", "déverrouillage"),
    ("rafraichissement", "rafraîchissement"),
    ("preselectionnee", "présélectionnée"),
    ("economises", "économisés"),
    ("reessayer", "réessayer"),
    ("1 element ", "1 élément "),
    (" element ", " élément "),
    (" deplace}", " déplacé}"),
    (" deplace ", " déplacé "),
    (" partage}", " partagé}"),
    (" partages}", " partagés}"),
    (" restaure}", " restauré}"),
    (" restaures}", " restaurés}"),
    (" supprime}", " supprimé}"),
]


def main() -> None:
    data = json.loads(ARB.read_text(encoding="utf-8"))
    for key, value in list(data.items()):
        if key.startswith("@") or not isinstance(value, str):
            continue
        if key in FIXES:
            data[key] = FIXES[key]
            continue
        updated = value
        for src, dst in GLOBAL_REPL:
            updated = updated.replace(src, dst)
        data[key] = updated

    ARB.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    rx = re.compile(
        r"(parametre|Reiniti|Decouvrir|Francais|systeme|acces|Echec|"
        r"bibliotheque|periode|geolocal|apparait|utilisee|Previsual|"
        r"Retention|fermee|Definir|deplacement|deverrou[^i]|economises|"
        r"preselection|rafraich|reessayer|1 element| element )",
        re.I,
    )
    left = [
        (k, v)
        for k, v in data.items()
        if not k.startswith("@") and isinstance(v, str) and rx.search(v)
    ]
    print(f"remaining={len(left)}")
    for key, value in left[:40]:
        print(f"{key}: {value}")


if __name__ == "__main__":
    main()
