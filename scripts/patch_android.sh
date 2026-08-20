#!/usr/bin/env bash
set -euo pipefail
MANIFEST="android/app/src/main/AndroidManifest.xml"
CONFIG="lib/core/supabase_config.dart"
if [ ! -f "$MANIFEST" ]; then
  echo "AndroidManifest.xml not found" >&2
  exit 1
fi
if [ ! -f "$CONFIG" ]; then
  echo "Supabase config not found" >&2
  exit 1
fi
python3 - "$MANIFEST" "$CONFIG" <<'PY'
from pathlib import Path
import re
import sys
from urllib.parse import urlparse

manifest = Path(sys.argv[1])
config = Path(sys.argv[2])
s = manifest.read_text()
config_text = config.read_text()

match = re.search(r"oauthRedirectUri\s*=\s*'([^']+)'", config_text)
if not match:
    raise SystemExit('Could not read oauthRedirectUri from SupabaseConfig')
callback = match.group(1)
parsed = urlparse(callback)
scheme = parsed.scheme
host = parsed.netloc
if not scheme or not host:
    raise SystemExit(f'Invalid oauthRedirectUri: {callback}')

permission = '    <uses-permission android:name="android.permission.INTERNET"/>'
if 'android.permission.INTERNET' not in s:
    end = s.find('>')
    if end < 0:
        raise SystemExit('Could not locate manifest root tag')
    s = s[:end + 1] + '\n' + permission + s[end + 1:]

if f'android:scheme="{scheme}"' not in s or f'android:host="{host}"' not in s:
    marker = '            <intent-filter>\n                <action android:name="android.intent.action.MAIN"/>'
    deeplink = f'''            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="{scheme}" android:host="{host}"/>
            </intent-filter>
'''
    if marker in s:
        s = s.replace(marker, deeplink + marker, 1)
    else:
        raise SystemExit('Could not locate main intent-filter marker')

manifest.write_text(s)
print(f'Android OAuth callback patched: {scheme}://{host}')
PY
