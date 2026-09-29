#!/bin/zsh
# Build dist/agentic-coding-playbook.zip — English PDF + markdown sources.
# Pipeline: concatenate docs → npx marked (GFM → HTML) → Chrome headless PDF → zip.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

# 1. Concatenate the playbook in reading order (README as cover/TOC, then docs 2-4)
COMBINED="$BUILD/combined.md"
: > "$COMBINED"
for f in README.md docs/meta-prompting-harness-loop-engineering.md docs/orca-ade-guide.md docs/lab-orca-parallel-agents.md; do
  cat "$REPO/$f" >> "$COMBINED"
  printf '\n\n<div style="page-break-after: always;"></div>\n\n' >> "$COMBINED"
done

# 2. Markdown -> HTML via marked
BODY="$BUILD/body.html"
npx --yes marked --gfm -i "$COMBINED" -o "$BODY"

# 3. Wrap with print styling
#    pre/code must wrap (pre-wrap + break-word): Chrome's print pipeline clips
#    overflowing code lines at the page margin, silently losing content.
cat > "$BUILD/playbook.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>The Agentic Coding Playbook</title>
<style>
  body { font-family: -apple-system, "Helvetica Neue", Arial, sans-serif; font-size: 11pt; line-height: 1.6; color: #1a1a1a; max-width: 46em; margin: 0 auto; padding: 2em; }
  h1 { font-size: 1.9em; border-bottom: 2px solid #333; padding-bottom: .3em; margin-top: 1.4em; }
  h2 { font-size: 1.4em; border-bottom: 1px solid #ccc; padding-bottom: .2em; margin-top: 1.3em; }
  h3 { font-size: 1.15em; margin-top: 1.2em; }
  code { font-family: "SF Mono", Menlo, Consolas, monospace; font-size: .88em; background: #f4f4f4; padding: .1em .3em; border-radius: 3px; overflow-wrap: break-word; }
  pre { background: #f6f8fa; padding: 1em; border-radius: 6px; white-space: pre-wrap; overflow-wrap: break-word; word-break: break-word; page-break-inside: avoid; }
  pre code { background: none; padding: 0; white-space: pre-wrap; overflow-wrap: break-word; word-break: break-word; }
  table { border-collapse: collapse; width: 100%; font-size: .92em; page-break-inside: avoid; }
  th, td { border: 1px solid #ccc; padding: .4em .6em; text-align: left; vertical-align: top; overflow-wrap: break-word; }
  th { background: #f0f0f0; }
  blockquote { border-left: 4px solid #bbb; margin-left: 0; padding-left: 1em; color: #444; }
  a { color: #0b5fa5; text-decoration: none; word-break: break-all; }
  h1, h2, h3 { page-break-after: avoid; }
</style>
</head>
<body>
EOF
cat "$BODY" >> "$BUILD/playbook.html"
printf '</body>\n</html>\n' >> "$BUILD/playbook.html"

# 4. HTML -> PDF via Chrome headless
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$BUILD/agentic-coding-playbook.pdf" \
  "file://$BUILD/playbook.html" 2>/dev/null

# 5. Assemble zip: English PDF + English markdown sources
STAGE="$BUILD/agentic-coding-playbook"
mkdir -p "$STAGE/docs"
cp "$BUILD/agentic-coding-playbook.pdf" "$STAGE/"
cp "$REPO/README.md" "$STAGE/"
cp "$REPO"/docs/*.md "$STAGE/docs/"
mkdir -p "$REPO/dist"
rm -f "$REPO/dist/agentic-coding-playbook.zip"
(cd "$BUILD" && zip -qr "$REPO/dist/agentic-coding-playbook.zip" agentic-coding-playbook)
cp "$BUILD/agentic-coding-playbook.pdf" "$REPO/dist/"

echo "Built: $REPO/dist/agentic-coding-playbook.zip"
unzip -l "$REPO/dist/agentic-coding-playbook.zip"
