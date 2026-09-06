# RC SOW — GitHub Production Factory

This workflow moves Flutter/Android build processing off Termux and onto GitHub Actions.

## What GitHub does

1. Checks out the source.
2. Installs pinned Flutter 3.44.7.
3. Canonically formats Dart and commits formatting repair on push builds.
4. Bootstraps Android if the platform folder is absent.
5. Applies the RC SOW Android/OAuth callback patch.
6. Resolves dependencies and records dependency evidence.
7. Generates launcher icon and native splash.
8. Runs `flutter analyze`.
9. Runs unit/widget tests with coverage.
10. Runs production capability/contract checks.
11. Builds a universal APK.
12. Builds split-per-ABI APKs.
13. Builds the Play Store AAB.
14. Packages an Android-ready source ZIP.
15. Packages editable operational document templates.
16. Generates SHA-256 checksums and an artifact manifest.
17. Uploads the complete factory output as GitHub Actions artifacts.

## What stays out of the build artifact

Do not commit signing secrets, service-role keys, `.env` files, keystores, or raw beneficiary assessment workbooks containing personal information. The packaging script explicitly excludes common secret files and raw Shelter Assessment spreadsheets from the source artifact.

## Termux after this patch

Termux only needs Git and GitHub CLI:

```bash
pkg install git gh unzip -y
cd ~/RC_SOW_Flutter_v18_2_Fusion_Production
git add .
git commit -m "Add RC SOW GitHub Production Factory"
git push origin main
```

Then check the run:

```bash
gh run list --limit 5
gh run view RUN_ID
```

Download from inside the repository:

```bash
gh run download RUN_ID --dir ~/RC_SOW_FACTORY_OUTPUT
```

Or from any directory:

```bash
gh run download RUN_ID \
  -R FOR3V3RLEARNG/RC_SOW_Flutter_v18_2_Fusion_Production \
  --dir ~/RC_SOW_FACTORY_OUTPUT
```

## Produced files

The main artifact contains APKs, AAB, source ZIP, editable template ZIP, checksums, manifest, dependency reports, analyzer output and test/coverage evidence.
