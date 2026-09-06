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


def oversized_numeric_icons(paths: list[str], limit: int = 24) -> list[tuple[str, int]]:
    failures: list[tuple[str, int]] = []
    pattern = re.compile(r"Icon\s*\([\s\S]{0,260}?size\s*:\s*(\d+(?:\.\d+)?)")
    for rel in paths:
        text = read(ROOT / rel)
        for match in pattern.finditer(text):
            size = float(match.group(1))
            if size > limit:
                failures.append((rel, round(size)))
    return failures


core_icon_oversize = oversized_numeric_icons(
    [
        "lib/features/dashboard/dashboard_screen.dart",
        "lib/features/control/control_screen.dart",
        "lib/features/control/record_form_screen.dart",
        "lib/features/admin/admin_screen.dart",
        "lib/features/community/community_screen.dart",
    ]
)

material3_enabled = bool(
    re.search(r"ThemeData\s*\([\s\S]{0,8000}?useMaterial3\s*:\s*true", lib_text)
)
material_theme_wired = (
    contains("lib/app.dart", "MaterialApp(")
    and contains("lib/app.dart", "buildRcTheme(")
)

forbidden_runtime_terms = re.compile(
    r"\b(demo data|mock data|fake data|placeholder data|sample beneficiary|sample house)\b",
    re.IGNORECASE,
)
production_source_clean = not forbidden_runtime_terms.search(lib_text)


# Regression guards for production failures found by the Fusion v20.4.1 audit.
dropdown_menu_item_initial_value = bool(
    re.search(r"DropdownMenuItem(?:<[^>]+>)?\s*\(\s*initialValue\s*:", lib_text)
)
factory_text = read(ROOT / ".github/workflows/rc-sow-production-factory.yml")
production_migration = read(
    ROOT / "supabase/migrations/20260906_rcsow_v20_3_production_operations.sql"
)

checks: list[tuple[str, bool]] = [
    ("Material 3 is enabled and wired", material3_enabled and material_theme_wired),
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
    (
        "Scalable product registry exists",
        contains("lib/core/product_registry.dart", "abstract final class RcProductRegistry"),
    ),
    (
        "v18.2 spacious icon contract exists",
        contains("lib/core/design_tokens.dart", "abstract final class RcIconSize")
        and contains("lib/core/design_tokens.dart", "abstract final class RcLayout"),
    ),
    (
        "Core production icons remain restrained",
        not core_icon_oversize
        and contains("lib/features/shell/app_shell.dart", "size: RcIconSize.sm"),
    ),
    (
        "Dynamic custom production forms are supported",
        contains("lib/services/rc_sow_repository.dart", "type.startsWith('custom:')"),
    ),
    (
        "Production migration is packaged",
        (ROOT / "supabase/migrations/20260906_rcsow_v20_3_production_operations.sql").is_file(),
    ),
    ("No runtime demo/placeholder data markers", production_source_clean),
    (
        "Dropdown menu items use value, not FormField initialValue",
        not dropdown_menu_item_initial_value,
    ),
    (
        "Production Factory does not race Green Gate pushes",
        "git push origin" not in factory_text,
    ),
    (
        "Evidence/signature paths preserve canonical parish names",
        contains("lib/services/rc_sow_repository.dart", "_parishSegment(parish)"),
    ),
    (
        "Crew assignment and attendance policies are parish scoped",
        "has_privilege('manageCrew') and public.can_access_parish(parish)" in production_migration
        and "has_privilege('verifyAttendance') and public.can_access_parish(parish)" in production_migration,
    ),
    (
        "Evidence writes are parish scoped",
        "public.has_privilege('reviewControl')) and public.can_access_parish((storage.foldername(name))[1])" in production_migration,
    ),
    (
        "Community publishing is Admin controlled",
        "v_role='Admin' and public.has_privilege('manageCommunity')" in production_migration,
    ),
    (
        "Production deletes remain on the audited RPC path",
        ".from('app_events')\n          .delete()" not in read(ROOT / "lib/services/rc_sow_repository.dart"),
    ),
    (
        "Gmail message body is decoded in-app",
        contains("lib/services/rc_sow_repository.dart", "_gmailBodyText")
        and contains("lib/features/gmail/gmail_screen.dart", "bodyText"),
    ),
    (
        "Community Board is read-only outside Admin",
        contains("lib/models/app_models.dart", "isAdmin && hasPrivilege('manageCommunity')"),
    ),
    (
        "PDF export avoids deprecated Table.fromTextArray",
        "Table.fromTextArray" not in read(ROOT / "lib/services/export_service.dart"),
    ),
    (
        "Crew assignment has a safe firstOrNull helper",
        contains("lib/features/workforce/crew_assignment_panel.dart", "extension _CrewFirstOrNull"),
    ),
]

for label, terms in [
    ("Messaging capability", ("message", "Message")),
    ("Settings capability", ("Settings", "settings")),
    ("Scope capability", ("Scope", "scope")),
    ("Control-of-Works capability", ("Control", "control")),
    ("House/beneficiary capability", ("House", "Beneficiary")),
    ("Attendance capability", ("crewAttendance", "Crew Daily Attendance")),
    ("Community capability", ("Community", "communitySuggestion")),
    ("Digital signature capability", ("signatureRequest", "Signature")),
]:
    checks.append((label, all(term in lib_text for term in terms)))

failed = [label for label, ok in checks if not ok]
for label, ok in checks:
    print(f"{'PASS' if ok else 'FAIL'}  {label}")

if not material3_enabled:
    print("INFO  No ThemeData(... useMaterial3: true ...) declaration was found in lib/.")
elif not material_theme_wired:
    print("INFO  Material 3 exists, but lib/app.dart does not wire buildRcTheme into MaterialApp.")


if core_icon_oversize:
    for rel, size in core_icon_oversize:
        print(f"INFO  Oversized production icon: {rel} -> {size}dp")

if failed:
    print("\nProduction contract failures:")
    for item in failed:
        print(f" - {item}")
    sys.exit(1)

print("\nAll RC SOW production contracts passed.")
