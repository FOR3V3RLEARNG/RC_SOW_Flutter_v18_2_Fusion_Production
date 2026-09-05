# RC SOW v20.0.0 — Gemini Build Runbook

## Recommended: interactive Gemini CLI

Gemini CLI automatically loads the root `GEMINI.md` as project context.

From the project root:

```bash
npm install -g @google/gemini-cli@latest
gemini -i "$(cat GEMINI_BUILD_MASTER_PROMPT.md)"
```

Interactive mode is recommended for repair/build work because you can review tool execution and continue the same engineering session.

## Headless / autonomous lane

Use only in a disposable or version-controlled working copy:

```bash
gemini --approval-mode yolo --output-format stream-json \
  -p "$(cat GEMINI_BUILD_MASTER_PROMPT.md)" \
  | tee gemini-build-session.jsonl
```

If your installed CLI does not recognize an option, run `gemini --help` and use the equivalent supported flag. Do not place API keys in this repository.

## Termux preparation

```bash
pkg update
pkg install nodejs-lts git -y
npm install -g @google/gemini-cli@latest
```

Then enter the extracted RC SOW project directory and launch the recommended interactive command above.

## Important build boundary

Gemini can edit/repair the source wherever it has file and shell access. The real Flutter APK/web/AAB build still requires a compatible Flutter/Dart/Android toolchain. If that toolchain is unavailable in Termux, use Gemini to repair the source and then push the branch so `.github/workflows/green_gate.yml` performs the Flutter build on GitHub Actions.

## GitHub release context

- branch context: `rc-sow-connected-v20.0.0`
- publication commit context: `d848a24`
- failed workflow run context: `33842027327`

These are diagnostic references from the publication attempt. Gemini should verify the actual repository state before acting.
