#!/usr/bin/env python3
"""Extract metadata + assets from .mrt theme archive for GitHub Actions."""

import argparse
import json
import os
import re
import sys
import zipfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Extract .mrt theme info")
    parser.add_argument("--mrt", required=True, help="Path to theme file (.zip/.mrt)")
    parser.add_argument("--outdir", default=".", help="Output directory")
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    try:
        with zipfile.ZipFile(args.mrt, "r") as zf:
            names = zf.namelist()

            if "theme.json" not in names:
                result = {"error": "theme.json missing from archive", "valid": False}
                print(json.dumps(result))
                sys.exit(1)

            theme_raw = zf.read("theme.json")
            theme_data = json.loads(theme_raw)
            meta = theme_data if isinstance(theme_data, dict) else {}

            theme_name = meta.get("name", "").strip() or os.environ.get("THEME_NAME", "Untitled")
            theme_author = meta.get("author", "").strip() or os.environ.get("THEME_AUTHOR", "Unknown")
            theme_version = meta.get("version", "").strip() or "1.0"
            theme_desc = meta.get("description", "").strip()
            fonts_required = meta.get("fonts_required", [])

            theme_id = re.sub(r"[^a-z0-9-]+", "-", theme_name.lower())
            theme_id = re.sub(r"-+", "-", theme_id).strip("-") or "theme"

            config = meta.get("config", {})

            preview_extracted = False
            if "preview.png" in names:
                (outdir / "preview.png").write_bytes(zf.read("preview.png"))
                preview_extracted = True

            font_files = []
            for entry in names:
                if entry.startswith("fonts/") and (
                    entry.endswith(".ttf") or entry.endswith(".otf")
                ):
                    fpath = outdir / entry
                    fpath.parent.mkdir(parents=True, exist_ok=True)
                    fpath.write_bytes(zf.read(entry))
                    font_files.append(entry)

            result = {
                "valid": True,
                "id": theme_id,
                "name": theme_name,
                "author": theme_author,
                "version": theme_version,
                "description": theme_desc,
                "has_preview": preview_extracted,
                "font_count": len(font_files),
                "fonts_required": fonts_required,
                "config_keys": list(config.keys()),
            }
            print(json.dumps(result))

    except zipfile.BadZipFile:
        print(json.dumps({"error": "Invalid ZIP", "valid": False}))
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid theme.json: {e}", "valid": False}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": str(e), "valid": False}))
        sys.exit(1)


if __name__ == "__main__":
    main()
