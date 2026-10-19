#!/bin/bash
# Runs SwiftFormat or SwiftLint for the pre-commit hook (lefthook.yml).
#
# The binaries come from the MAIN checkout's .build/tools, so a fresh worktree
# commits without building its own copy (~20 s and ~1 GB per worktree). A
# worktree whose Package.swift pins different tool versions builds its own.
#
# SwiftLint runs as the plain binary, not the SPM command plugin: inside the
# plugin sandbox a worktree's file arguments fail the plugin's existence check,
# so it falls back to linting the whole tree, .build included.
#
# Usage: Scripts/lint-tool.sh swiftformat|swiftlint [args…]
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
main="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
pkg="$main"
cmp -s "$root/Package.swift" "$main/Package.swift" || pkg="$root"
tools="$pkg/.build/tools"

case "${1:-}" in
  swiftformat) bin="$tools/debug/swiftformat" ;;
  swiftlint) bin="$tools/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint" ;;
  *) echo "usage: $0 swiftformat|swiftlint [args…]" >&2; exit 2 ;;
esac
shift

# Building SwiftFormat resolves the whole tool graph, which also downloads the
# SwiftLint binary. Redo it whenever the pins change, not just when it's missing.
stamp="$tools/.lint-tool-stamp"
want="$(cat "$pkg/Package.swift" "$pkg/Package.resolved" 2>/dev/null | shasum | cut -d' ' -f1)"
if [ ! -x "$bin" ] || [ "$(cat "$stamp" 2>/dev/null)" != "$want" ]; then
  echo "Building SwiftFormat/SwiftLint in $tools (once per tool-version change)…" >&2
  swift build --package-path "$pkg" --build-path "$tools" --product swiftformat >&2
  echo "$want" >"$stamp"
fi

exec "$bin" "$@"
