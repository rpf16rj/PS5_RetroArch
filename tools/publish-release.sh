#!/usr/bin/env bash
# PS5 RetroArch - package the locally built title and publish it as a
# GitHub release on this fork.
#
#   tools/publish-release.sh                  today: vYYYY-MM-DD
#   tools/publish-release.sh v2026-10-05      explicit tag
#   tools/publish-release.sh --dir <folder>   package this title folder
#   tools/publish-release.sh --dry-run        print everything, touch nothing
#   tools/publish-release.sh --edit           review the notes before release
#
# Nothing here compiles: the build is the local WSL pipeline
# (tools/build-title.sh). This script finds the built title folder, zips it,
# tags HEAD with the date-version, pushes the tag, and creates the release
# with the friendly notes from tools/release-notes.sh.

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

version=""
dry_run=false
edit_notes=false
dist_dir=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) dry_run=true ;;
        --edit)    edit_notes=true ;;
        --dir)     dist_dir=$2; shift ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        v*)        version=$1 ;;
        *)         echo "error: unknown argument '$1'" >&2; exit 2 ;;
    esac
    shift
done
# Releases are dated, not semver: today's date is the version.
version=${version:-v$(date +%Y-%m-%d)}

title_id=$(python3 - "$root/sce_sys/param.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))["titleId"])
PY
)
[[ -n $title_id ]] || { echo "error: no titleId in sce_sys/param.json" >&2; exit 2; }

# The title folder: an explicit --dir wins, then the build output, then the
# handoff copy.
if [[ -z $dist_dir ]]; then
    for candidate in "dist/$title_id" "handoff/$title_id" \
                     "$root/../flycast_ps5_core/$title_id"; do
        if [[ -f $candidate/eboot.bin ]]; then
            dist_dir=$candidate
            break
        fi
    done
fi
[[ -n $dist_dir && -f $dist_dir/eboot.bin ]] \
    || { echo "error: no built title folder found - pass --dir <folder> or build first" >&2; exit 2; }
[[ -f $dist_dir/sce_sys/param.json ]] \
    || { echo "error: $dist_dir has an eboot.bin but no sce_sys/param.json" >&2; exit 2; }
echo "==> title folder: $dist_dir"

# --- Notes -------------------------------------------------------------------
notes=$(mktemp --suffix=.md)
bash "$root/tools/release-notes.sh" "$version" > "$notes"
if $edit_notes; then
    "${VISUAL:-${EDITOR:-notepad}}" "$notes" || true
fi
echo "==> release notes:"
cat "$notes"

# --- Package -----------------------------------------------------------------
out_dir="$root/build/releases"
mkdir -p "$out_dir"
zip_name="RetroArch-PS5-${version}.zip"
zip_path="$out_dir/$zip_name"
rm -f -- "$zip_path"
if $dry_run; then
    echo "==> [dry-run] would zip $dist_dir -> $zip_path"
else
    # Zip the folder's contents: the player extracts over the app0 tree.
    if command -v zip >/dev/null; then
        (cd "$dist_dir" && zip -qr "$zip_path" .)
    else
        tar -a -cf "$zip_path" -C "$dist_dir" .
    fi
    echo "==> packaged: $zip_path ($(du -h "$zip_path" | cut -f1))"
fi

assets=("$zip_path")
for pkg in "$root/dist/$title_id.ffpkg" "$root/dist/$title_id.ffpfsc"; do
    [[ -f $pkg ]] && assets+=("$pkg")
done

# --- Tag + release -----------------------------------------------------------
if $dry_run; then
    echo "==> [dry-run] would tag $version and upload: ${assets[*]}"
    rm -f "$notes"
    exit 0
fi

if ! git rev-parse -q --verify "refs/tags/$version" >/dev/null; then
    git tag -a "$version" -m "RetroArch for PlayStation 5 $version"
    echo "==> tagged $version"
fi
git push origin "$version"
echo "==> pushed tag $version"

if gh release view "$version" >/dev/null 2>&1; then
    gh release upload "$version" "${assets[@]}" --clobber
    gh release edit "$version" \
        --title "RetroArch for PlayStation 5 $version" --notes-file "$notes"
    echo "==> updated existing release $version"
else
    gh release create "$version" \
        --title "RetroArch for PlayStation 5 $version" \
        --notes-file "$notes" \
        "${assets[@]}"
    echo "==> created release $version"
fi
rm -f "$notes"
gh release view "$version" --json url --jq .url
