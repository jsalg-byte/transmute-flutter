#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release_version="${1:-$(date -u +%Y%m%dT%H%M%SZ)}"

case "$release_version" in
  *[!A-Za-z0-9._-]*)
    echo "Release version may only contain letters, digits, dots, underscores, and hyphens." >&2
    exit 1
    ;;
esac

cd "$project_root"
.fvm/flutter_sdk/bin/flutter build web --release --no-wasm-dry-run \
  --dart-define=TRANSMUTE_REPOSITORY_MODE=api \
  --dart-define=TRANSMUTE_API_BASE_URL=https://api.transmute.mzootfb.xyz
rsync -a --delete build/web/ release/web/

# Flutter's entrypoint filenames stay constant between builds. Version their
# URLs so a browser cannot reuse a previously immutable bootstrap/app bundle.
perl -0pi -e "s{src=\"flutter_bootstrap\\.js(?:\\?v=[^\"]*)?\"}{src=\"flutter_bootstrap.js?v=$release_version\"}" release/web/index.html
perl -0pi -e "s{\"mainJsPath\":\"main\\.dart\\.js(?:\\?v=[^\"]*)?\"}{\"mainJsPath\":\"main.dart.js?v=$release_version\"}" release/web/flutter_bootstrap.js

echo "Built release/web with cache version $release_version"
