#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.is_file() else ""


def contains(path: str, needle: str) -> bool:
    return needle in read(ROOT / path)


def dart_sources() -> list[Path]:
    return sorted(LIB.rglob("*.dart")) if LIB.is_dir() else []


sources = dart_sources()
lib_text = "\n".join(read(path) for path in sources)

# Material 3 can legitimately be declared in a theme module rather than app.dart.
# Require an actual ThemeData configuration with useMaterial3: true somewhere in
# production Dart source, and require MaterialApp to consume the RC theme builder.
material3_enabled = bool(
    re.search(r"ThemeData\s*\([\s\S]{0,6000}?useMaterial3\s*:\s*true", lib_text)
)
material_theme_wired = (
    contains("lib/app.dart", "MaterialApp(")
    and contains("lib/app.dart", "buildRcTheme(")
)

checks: list[tuple[str, bool]] = [
    ("Material 3 is enabled", material3_enabled and material_theme_wired),
    ("Supabase configuration exists", (ROOT / "lib/core/supabase_config.dart").is_file()),
    (
        "OAuth callback scheme is canonical",
        contains("lib/core/supabase_config.dart", "org.jamaicaredcross.rcsowflutter"),
    ),
    ("Android patch script exists", (ROOT / "scripts/patch_android.sh").is_file()),
    (
        "Unit tests exist",
        (ROOT / "test").is_dir() and any((ROOT / "test").rglob("*_test.dart")),
    ),
    ("Integration-test source exists", (ROOT / "integration_test").is_dir()),
]

# Capability checks intentionally avoid coupling the factory to one widget name.
for label, terms in [
    ("Messaging capability", ("message", "Message")),
    ("Settings capability", ("Settings", "settings")),
    ("Scope capability", ("Scope", "scope")),
    ("Control-of-Works capability", ("Control", "control")),
    ("House/beneficiary capability", ("House", "Beneficiary")),
]:
    checks.append((label, any(term in lib_text for term in terms)))

failed = [label for label, ok in checks if not ok]
for label, ok in checks:
    print(f"{'PASS' if ok else 'FAIL'}  {label}")

if not material3_enabled:
    print("INFO  No ThemeData(... useMaterial3: true ...) declaration was found in lib/.")
elif not material_theme_wired:
    print("INFO  Material 3 exists, but lib/app.dart does not wire buildRcTheme into MaterialApp.")

if failed:
    print("\nProduction contract failures:")
    for item in failed:
        print(f" - {item}")
    sys.exit(1)

print("\nAll production contract checks passed.")
