#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"


def read(path: str) -> str:
    target = ROOT / path
    return target.read_text(encoding="utf-8", errors="ignore") if target.is_file() else ""


def contains(path: str, needle: str) -> bool:
    return needle in read(path)


lib_text = "\n".join(
    path.read_text(encoding="utf-8", errors="ignore")
    for path in sorted(LIB.rglob("*.dart"))
)

material3_enabled = bool(
    re.search(r"ThemeData\s*\([\s\S]{0,8000}?useMaterial3\s*:\s*true", lib_text)
)

checks: list[tuple[str, bool]] = [
    (
        "Material 3 theme is wired",
        material3_enabled
        and contains("lib/app.dart", "MaterialApp(")
        and contains("lib/app.dart", "buildRcTheme("),
    ),
    (
        "Light/dark/system appearance is wired",
        contains("lib/app.dart", "themeMode: state.themeMode")
        and contains("lib/app.dart", "darkTheme:")
        and contains("lib/state/app_state.dart", "ThemeMode themeMode"),
    ),
    (
        "OAuth callback is centralized",
        contains("lib/core/supabase_config.dart", "org.jamaicaredcross.rcsowflutter")
        and contains("lib/features/auth/login_screen.dart", "SupabaseConfig.oauthRedirectUri"),
    ),
    (
        "Message drawer is interactive",
        contains("lib/features/messages/messages_screen.dart", "_detailView")
        and contains("lib/features/messages/messages_screen.dart", "_replyFromDrawer"),
    ),
    (
        "Online users are really online",
        contains("lib/services/rc_sow_repository.dart", ".where((record) => record.online)"),
    ),
    (
        "Online user can open direct message",
        contains("lib/features/users/active_users_screen.dart", "composeTo: user.email"),
    ),
    (
        "Gmail UI is connected",
        (ROOT / "lib/features/messages/gmail_screen.dart").is_file()
        and contains("lib/features/settings/settings_screen.dart", "GmailScreen(state: state)"),
    ),
    (
        "File Picker v12 save contract is satisfied",
        contains("lib/services/document_service.dart", "mimeType: template.mimeType")
        and contains("lib/services/document_service.dart", "mimeType: mimeType"),
    ),
    (
        "Excel Plus save API is used",
        contains("lib/services/document_service.dart", "package:excel_plus/excel_plus.dart")
        and contains("lib/services/document_service.dart", "excel.save()"),
    ),
    (
        "Control modules create real records",
        all(
            event_type in read("lib/features/control/control_screen.dart")
            for event_type in (
                "workPlan",
                "monitoring",
                "siteVisit",
                "dailyLog",
                "documentChecklist",
                "materialRequest",
                "consumables",
                "inventory",
                "notice",
                "payment",
            )
        )
        and "preserved as a dedicated Control of Works submodule" not in read(
            "lib/features/control/control_screen.dart"
        ),
    ),
    (
        "Production PDF and Excel exports are wired",
        contains("lib/features/control/control_screen.dart", "productionXlsx")
        and contains("lib/features/control/control_screen.dart", "productionPdf"),
    ),
    (
        "Scope parish selector and Shelter Assessment lookup are wired",
        contains("lib/features/scope/scope_screen.dart", "RcPolicy.parishes")
        and contains("lib/features/scope/scope_screen.dart", "_BeneficiaryLookup")
        and contains("lib/features/scope/scope_screen.dart", "beneficiaries("),
    ),
    (
        "Scope digital signature and PDF/Excel export are wired",
        contains("lib/features/scope/scope_screen.dart", "SignaturePad")
        and contains("lib/features/scope/scope_screen.dart", "scopeXlsx")
        and contains("lib/features/scope/scope_screen.dart", "MemoryImage"),
    ),
    (
        "Only Green Gate mutates formatting",
        "git push origin" in read(".github/workflows/flutter-green-gate.yml")
        and "git push origin" not in read(".github/workflows/rc-sow-production-factory.yml"),
    ),
    (
        "Unit tests exist",
        (ROOT / "test").is_dir() and any((ROOT / "test").rglob("*_test.dart")),
    ),
]

failed = [label for label, ok in checks if not ok]
for label, ok in checks:
    print(f"{'PASS' if ok else 'FAIL'}  {label}")

if failed:
    print("\nFusion production contract failures:")
    for label in failed:
        print(f" - {label}")
    sys.exit(1)

print("\nAll RC SOW v18.3.1 Fusion production contracts passed.")
