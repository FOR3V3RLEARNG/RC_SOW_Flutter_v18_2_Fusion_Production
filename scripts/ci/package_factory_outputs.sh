#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT="$ROOT/factory_output"
mkdir -p "$OUT/apk" "$OUT/aab" "$OUT/templates" "$OUT/source" "$OUT/reports"

# Android deliverables.
cp build/app/outputs/flutter-apk/app-release.apk "$OUT/apk/RC_SOW-universal-release.apk"
find build/app/outputs/flutter-apk -maxdepth 1 -type f -name 'app-*-release.apk' -exec cp {} "$OUT/apk/" \;
cp build/app/outputs/bundle/release/app-release.aab "$OUT/aab/RC_SOW-release.aab"

# Validation/build evidence.
cp -a logs/. "$OUT/reports/" 2>/dev/null || true
cp -a coverage "$OUT/reports/coverage" 2>/dev/null || true

# Original editable operational templates. Raw beneficiary assessment workbooks
# are deliberately excluded from release packaging because they may contain PII.
if [ -d assets/templates/original ]; then
  find assets/templates/original -maxdepth 1 -type f \
    \( -name '*.xlsx' -o -name '*.docx' -o -name '*.pdf' \) \
    ! -iname '*Shelter*Assessment*' \
    -exec cp {} "$OUT/templates/" \;
fi

# Create a generated Android-ready source package while excluding VCS, caches,
# build outputs, secrets and raw beneficiary datasets.
SOURCE_STAGE="$(mktemp -d)"
trap 'rm -rf "$SOURCE_STAGE"' EXIT
mkdir -p "$SOURCE_STAGE/RC_SOW_Source"
rsync -a ./ "$SOURCE_STAGE/RC_SOW_Source/" \
  --exclude '.git/' \
  --exclude '.dart_tool/' \
  --exclude 'build/' \
  --exclude 'factory_output/' \
  --exclude 'logs/' \
  --exclude 'coverage/' \
  --exclude '*.jks' \
  --exclude '*.keystore' \
  --exclude 'key.properties' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '*Shelter*Assessment*.xlsx'

(
  cd "$SOURCE_STAGE"
  zip -qr "$OUT/source/RC_SOW-GitHub-Ready-Source.zip" RC_SOW_Source
)

if find "$OUT/templates" -type f -maxdepth 1 | grep -q .; then
  (
    cd "$OUT/templates"
    zip -q "$OUT/RC_SOW-Editable-Document-Templates.zip" ./*
  )
fi

cat > "$OUT/ARTIFACT_MANIFEST.txt" <<EOF
RC SOW GitHub Production Factory
Run: ${GITHUB_RUN_ID:-local}
Run number: ${GITHUB_RUN_NUMBER:-local}
Commit: ${GITHUB_SHA:-local}
Branch: ${GITHUB_REF_NAME:-local}
Flutter: ${FLUTTER_VERSION:-3.44.7}
Package: org.jamaicaredcross.rc_sow_flutter
OAuth callback: org.jamaicaredcross.rcsowflutter://login-callback

Contents:
- apk/RC_SOW-universal-release.apk
- apk/app-*-release.apk (per ABI, when generated)
- aab/RC_SOW-release.aab
- source/RC_SOW-GitHub-Ready-Source.zip
- RC_SOW-Editable-Document-Templates.zip (when templates are present)
- reports/ validation evidence
- SHA256SUMS.txt
EOF

(
  cd "$OUT"
  find . -type f ! -name SHA256SUMS.txt -print0 \
    | sort -z \
    | xargs -0 sha256sum > SHA256SUMS.txt
)

echo 'Factory outputs:'
find "$OUT" -maxdepth 3 -type f -printf '%P\n' | sort
