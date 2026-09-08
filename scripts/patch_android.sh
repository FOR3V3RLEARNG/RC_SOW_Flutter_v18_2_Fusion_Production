#!/usr/bin/env bash
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
CONFIG="lib/core/supabase_config.dart"
RES="android/app/src/main/res"
GRADLE_PROPS="android/gradle.properties"

if [ ! -f "$MANIFEST" ]; then
  echo "AndroidManifest.xml not found" >&2
  exit 1
fi
if [ ! -f "$CONFIG" ]; then
  echo "Supabase config not found" >&2
  exit 1
fi

python3 - "$MANIFEST" "$CONFIG" <<'PY_OAUTH'
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

permissions = [
    'android.permission.INTERNET',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.POST_NOTIFICATIONS',
]
for permission_name in permissions:
    if permission_name not in s:
        end = s.find('>')
        if end < 0:
            raise SystemExit('Could not locate manifest root tag')
        permission = f'    <uses-permission android:name="{permission_name}"/>'
        s = s[:end + 1] + '\n' + permission + s[end + 1:]

if f'android:scheme="{scheme}"' not in s or f'android:host="{host}"' not in s:
    marker = '            <intent-filter>\n                <action android:name="android.intent.action.MAIN"/>'
    deeplink = (
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.VIEW"/>\n'
        '                <category android:name="android.intent.category.DEFAULT"/>\n'
        '                <category android:name="android.intent.category.BROWSABLE"/>\n'
        f'                <data android:scheme="{scheme}" android:host="{host}"/>\n'
        '            </intent-filter>\n'
    )
    if marker not in s:
        raise SystemExit('Could not locate main intent-filter marker')
    s = s.replace(marker, deeplink + marker, 1)

application_match = re.search(r'<application\b[^>]*>', s)
if not application_match:
    raise SystemExit('Could not locate Android application tag')
application_tag = application_match.group(0)
if 'android:label=' in application_tag:
    application_tag = re.sub(
        r'android:label="[^"]*"',
        'android:label="Red Cross Scope of Work"',
        application_tag,
        count=1,
    )
else:
    application_tag = application_tag[:-1] + ' android:label="Red Cross Scope of Work">'
s = s[:application_match.start()] + application_tag + s[application_match.end():]

manifest.write_text(s)
print(f'Android OAuth callback patched: {scheme}://{host}')
print('Android install name: Red Cross Scope of Work')
PY_OAUTH

# RC SOW embedded media: Android minSdk 24 for modern WebView support.
python3 - <<'PY_MINSDK'
from pathlib import Path
import re

for path in [Path('android/app/build.gradle.kts'), Path('android/app/build.gradle')]:
    if not path.exists():
        continue
    text = path.read_text()
    original = text
    text = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', text)
    text = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', text)
    if text != original:
        path.write_text(text)
        print(f'Android minSdk patched to 24: {path}')
PY_MINSDK

mkdir -p \
  "$RES/values" \
  "$RES/values-v31" \
  "$RES/values-night-v31" \
  "$RES/drawable" \
  "$RES/drawable-v21" \
  "$RES/raw" \
  "android/app/src/main/kotlin/org/jamaicaredcross/rc_sow_flutter"

cat > "$RES/values/colors.xml" <<'EOF_COLORS'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="rc_splash_background">#F4F7FB</color>
</resources>
EOF_COLORS

for target in \
  "$RES/drawable/launch_background.xml" \
  "$RES/drawable-v21/launch_background.xml"; do
  cat > "$target" <<'EOF_DRAWABLE'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/rc_splash_background"/>
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_launcher"/>
    </item>
</layer-list>
EOF_DRAWABLE
done

cat > "$RES/values-v31/styles.xml" <<'EOF_V31'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowSplashScreenBackground">@color/rc_splash_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@color/rc_splash_background</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:navigationBarColor">@color/rc_splash_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOF_V31

cat > "$RES/values-night-v31/styles.xml" <<'EOF_NIGHT_V31'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowSplashScreenBackground">@color/rc_splash_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@color/rc_splash_background</item>
        <item name="android:navigationBarColor">@color/rc_splash_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOF_NIGHT_V31

touch "$GRADLE_PROPS"
if grep -q '^org.gradle.vfs.watch=' "$GRADLE_PROPS"; then
  sed -i 's/^org\.gradle\.vfs\.watch=.*/org.gradle.vfs.watch=false/' "$GRADLE_PROPS"
else
  printf '\n# RC SOW CI stability: avoid duplicate Android VFS watcher crashes.\norg.gradle.vfs.watch=false\n' >> "$GRADLE_PROPS"
fi


cp assets/sounds/construction_alert.wav "$RES/raw/construction_alert.wav"

cat > "android/app/src/main/kotlin/org/jamaicaredcross/rc_sow_flutter/MainActivity.kt" <<'EOF_MAIN'
package org.jamaicaredcross.rc_sow_flutter

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOperationsNotificationChannel()
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2048)
        }
    }

    private fun createOperationsNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val sound = Uri.parse("android.resource://$packageName/${R.raw.construction_alert}")
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            "operations_construction",
            "RC SOW Construction Alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Messages, production alerts, signatures and construction actions"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 120, 80, 180)
            setSound(sound, audio)
        }
        manager.createNotificationChannel(channel)
    }
}
EOF_MAIN

echo "Android native splash + construction notification channel patched."
