#!/usr/bin/env bash
# PS5 RetroArch - generate the friendly release notes for a tag.
#
#   tools/release-notes.sh v0.7.0              notes for HEAD's changes
#   tools/release-notes.sh v0.7.0 v0.6.0       notes for v0.6.0..HEAD
#
# The notes readers see are release notes, not a commit dump: the commit log
# is filtered so only user-visible entries survive. Anything that names the
# machinery - scripts, the format gate, linking, pins, README edits - is left
# out, because a changelog line like "sampler_ps5.cpp: clang-format" tells a
# player nothing.

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

tag=${1:?usage: release-notes.sh <tag> [prev-tag]}
prev=${2:-$(git describe --tags --abbrev=0 "${tag}^" 2>/dev/null || true)}
[[ $tag != HEAD ]] || { echo "error: tag name required, not HEAD" >&2; exit 2; }

if [[ -n $prev ]]; then
    range="${prev}..HEAD"
else
    range="HEAD"
fi

# What stays OUT of the notes: repository plumbing, tooling and build
# machinery - plus anything naming a source file or a path, which is always
# an implementation detail. The list errs on the side of dropping: a missing
# line is a quieter release, a technical line is a worse one.
# NOTE: GNU grep ERE has no (?i); case-insensitivity comes from grep -i.
drop='(readme|legal|licen[cs]e|notice|changelog|release[sd]? |version bump|bump|merge|revert|fixup|squash|wip|clang-format|format gate|lint|style|typo|comment|commit(ted)?|markdown|makefile|cmake|toolchain|tooling|tools/|script|\.sh\b|workflow|github|link|linker|linking|import|export|symbol|relocat|binding|abi\b|elf\b|crt\b|libc\b|sdk\b|deps|dependency|pin\b|upstream|vendor|stub|trace|tracer|sampler|probe|diagnostic|instrument|test|assert|checkpoint|klog|log(s|ging)[: ]|thread-local|tls\b|mmap|page[- ]?size|syscall|ninja|compile|compiler|configure|header[s]?[:/ ]|refactor|cleanup|clean up|dead code|warning[s]?\b|error path|crash path|guard[s]?[: ]|hack|workaround|baseline|handoff|manifest|sha256|packaging|ffpkg|ffpfsc|param\.json|eboot|getcwd|platform|dir\b|path[: ]|[A-Za-z0-9_.-]+\.(c|cpp|h|hpp|py|sh|txt|json|md|yml|yaml|inc|a|o|bin)\b|/[A-Za-z0-9_.-]+/)'

echo "# RetroArch for PlayStation 5 — ${tag}"
echo
echo "RetroArch running natively on jailbroken PlayStation 5 consoles."
echo
if notes=$(git log --no-merges --pretty=%s "$range" | grep -viE "$drop" || true); [[ -n $notes ]]; then
    echo "## What's new"
    echo
    while IFS= read -r line; do
        # Sentence-case bullets read better than raw commit subjects.
        line="${line%.}."
        echo "- ${line}"
    done <<< "$notes"
    echo
else
    echo "Maintenance release."
    echo
fi
cat <<'EOF'
## Install

This title runs on a jailbroken PS5 with a payload loader. Extract the ZIP
and copy its contents over the RetroArch directory on the console
(`/data/homebrew/PPSA99169/` or `/usb0/homebrew/PPSA99169/`), or install the
package file with your loader if one is attached.

Cores live in `cores/`. Additional cores ship as their own releases - the
Flycast Dreamcast/Naomi core, for example, is published at
rpf16rj/flycast-ps5-libretro-core.

If a freshly installed core does not appear in the core list, delete
`info/core_info.cache` and restart RetroArch.
EOF
