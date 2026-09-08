#!/usr/bin/env bash
#
# Sync SurrealDB Agent Skills into the surrealdb power.
#
# `surrealdb/agent-skills` is upstream for the eight knowledge skills. The three
# skills authored here (see PROTECTED_SKILLS) are never touched.
#
# Every synced skill carries a `.sync-source.json` stamp recording the upstream
# commit and a hash of exactly what upstream provided. On a later run, a skill
# whose files no longer match that hash has local edits, and is skipped rather
# than silently reverted. That is the signal to upstream the change — pass
# --force to discard it instead.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_TARGET_DIR="$ROOT_DIR/plugins/surrealdb/skills"
DEFAULT_REPO_URL="https://github.com/surrealdb/agent-skills.git"
DEFAULT_REF="main"
PROTECTED_SKILLS=("getting-started" "surrealdb-connection" "surrealdb-mcp")

SOURCE_DIR=""
TARGET_DIR="$DEFAULT_TARGET_DIR"
REPO_URL="$DEFAULT_REPO_URL"
REF="$DEFAULT_REF"
KEEP_TEMP=0
FORCE=0
CHECK_ONLY=0

usage() {
	cat <<'USAGE'
Sync SurrealDB Agent Skills into the surrealdb power.

Usage:
  scripts/sync-agent-skills.sh [--source /path/to/agent-skills] [--target /path/to/skills]
                               [--repo <url>] [--ref main] [--check] [--force] [--keep-temp]

Options:
  --source    Use an existing local checkout instead of cloning.
  --target    Destination skills directory.
  --repo      Git repository to clone when --source is not given.
  --ref       Branch, tag, or commit to clone. Default: main
  --check     Report what would change and exit non-zero if anything would;
              write nothing.
  --force     Overwrite skills that have local edits.
  --keep-temp Leave the temporary clone on disk.
  -h, --help  Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--source) SOURCE_DIR="${2:-}"; shift 2 ;;
		--target) TARGET_DIR="${2:-}"; shift 2 ;;
		--repo) REPO_URL="${2:-}"; shift 2 ;;
		--ref) REF="${2:-}"; shift 2 ;;
		--check) CHECK_ONLY=1; shift ;;
		--force) FORCE=1; shift ;;
		--keep-temp) KEEP_TEMP=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "Unknown argument: $1" >&2; echo >&2; usage >&2; exit 1 ;;
	esac
done

is_protected_skill() {
	local candidate="$1" protected
	for protected in "${PROTECTED_SKILLS[@]}"; do
		[ "$candidate" = "$protected" ] && return 0
	done
	return 1
}

# Hash of a skill's SKILL.md plus references/, path-sensitive and order-stable.
# .sync-source.json is excluded so the stamp does not hash itself.
hash_skill() {
	local dir="$1"
	[ -d "$dir" ] || { echo "absent"; return; }
	(
		cd "$dir"
		find . -type f ! -name '.sync-source.json' -print0 |
			LC_ALL=C sort -z |
			xargs -0 shasum -a 256 |
			shasum -a 256 |
			awk '{print $1}'
	)
}

write_stamp() {
	local dir="$1" name="$2" hash="$3"
	cat > "$dir/.sync-source.json" <<EOF
{
	"repo": "$REPO_URL",
	"ref": "$REF",
	"commit": "$COMMIT_SHA",
	"skill": "$name",
	"upstream_sha256": "$hash"
}
EOF
}

recorded_hash() {
	local stamp="$1/.sync-source.json"
	[ -f "$stamp" ] || { echo ""; return; }
	python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("upstream_sha256",""))' "$stamp" 2>/dev/null || echo ""
}

TEMP_DIR=""
cleanup() {
	if [ -n "$TEMP_DIR" ] && [ "$KEEP_TEMP" -ne 1 ]; then
		rm -rf "$TEMP_DIR"
	fi
}
trap cleanup EXIT

if [ -z "$SOURCE_DIR" ]; then
	TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/surreal-agent-skills.XXXXXX")"
	SOURCE_DIR="$TEMP_DIR/agent-skills"
	echo "Cloning $REPO_URL@$REF into $SOURCE_DIR"
	git clone --quiet --depth 1 --branch "$REF" "$REPO_URL" "$SOURCE_DIR"
else
	SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
fi

if [ ! -d "$SOURCE_DIR/skills" ]; then
	echo "Expected a skills directory at $SOURCE_DIR/skills" >&2
	exit 1
fi

COMMIT_SHA="$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
mkdir -p "$TARGET_DIR"

SYNCED=0
SKIPPED=0
PENDING=0

for skill_dir in "$SOURCE_DIR"/skills/*; do
	[ -d "$skill_dir" ] || continue
	skill_name="$(basename "$skill_dir")"

	if is_protected_skill "$skill_name"; then
		echo "protected  $skill_name (authored here, never synced)"
		continue
	fi
	if [ ! -f "$skill_dir/SKILL.md" ]; then
		echo "skip       $skill_name (no SKILL.md upstream)"
		continue
	fi

	target_skill_dir="$TARGET_DIR/$skill_name"
	upstream_hash="$(hash_skill "$skill_dir")"
	local_hash="$(hash_skill "$target_skill_dir")"
	stamped_hash="$(recorded_hash "$target_skill_dir")"

	if [ "$local_hash" = "$upstream_hash" ]; then
		# Already identical to upstream. Refresh the stamp so the commit and the
		# baseline hash stay accurate, then move on.
		if [ "$CHECK_ONLY" -ne 1 ]; then
			write_stamp "$target_skill_dir" "$skill_name" "$upstream_hash"
		fi
		echo "current    $skill_name"
		continue
	fi

	if [ -n "$stamped_hash" ] && [ "$local_hash" != "$stamped_hash" ] && [ "$FORCE" -ne 1 ]; then
		echo "LOCAL EDIT $skill_name — differs from the synced baseline; upstream the change or pass --force"
		SKIPPED=$((SKIPPED + 1))
		continue
	fi

	if [ "$CHECK_ONLY" -eq 1 ]; then
		echo "would sync $skill_name"
		PENDING=$((PENDING + 1))
		continue
	fi

	mkdir -p "$target_skill_dir"
	cp "$skill_dir/SKILL.md" "$target_skill_dir/SKILL.md"
	rm -rf "$target_skill_dir/references"
	if [ -d "$skill_dir/references" ]; then
		mkdir -p "$target_skill_dir/references"
		cp -R "$skill_dir/references"/. "$target_skill_dir/references"/
	fi

	write_stamp "$target_skill_dir" "$skill_name" "$upstream_hash"

	echo "synced     $skill_name"
	SYNCED=$((SYNCED + 1))
done

if [ "$CHECK_ONLY" -eq 1 ]; then
	echo
	echo "$PENDING skill(s) would change, $SKIPPED with local edits."
	# Local edits are a standing condition here (two content fixes not yet
	# upstreamed), so only pending upstream changes are treated as a failure.
	if [ "$PENDING" -ne 0 ]; then
		exit 1
	fi
	exit 0
fi

echo
echo "Synced $SYNCED skill(s) from $REPO_URL@$COMMIT_SHA; skipped $SKIPPED with local edits."
