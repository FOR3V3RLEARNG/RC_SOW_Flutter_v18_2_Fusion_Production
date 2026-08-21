#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]

checks: list[tuple[str, bool]] = []

def contains(path: str, needle: str) -> bool:
    p = ROOT / path
    return p.is_file() and needle in p.read_text(encoding="utf-8", errors="ignore")

checks.extend([
    ("Material 3 is enabled", contains("lib/app.dart", "useMaterial3")),
    ("Supabase configuration exists", (ROOT / "lib/core/supabase_config.dart").is_file()),
    ("OAuth callback scheme is canonical", contains("lib/core/supabase_config.dart", "org.jamaicaredcross.rcsowflutter")),
    ("Android patch script exists", (ROOT / "scripts/patch_android.sh").is_file()),
    ("Unit tests exist", (ROOT / "test").is_dir() and any((ROOT / "test").rglob("*_test.dart"))),
    ("Integration-test source exists", (ROOT / "integration_test").is_dir()),
])

# These are intentionally capability checks rather than assumptions about exact
# implementation names. They help CI detect accidental removal as Fusion evolves.
lib_text = "\n".join(
    p.read_text(encoding="utf-8", errors="ignore")
    for p in (ROOT / "lib").rglob("*.dart")
)
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

if failed:
    print("\nProduction contract failures:")
    for item in failed:
        print(f" - {item}")
    sys.exit(1)

print("\nAll production contract checks passed.")
