#!/usr/bin/env bash
#
# Validate every plugin in this repo against Agent Plugins 1.0.0.
#
# Checks the parts a client will reject or silently skip: manifest fields, the
# `type` on every MCP server entry, Kiro-only fields that have no place in the
# plugin format, `${VAR}` in a url or header (which is never expanded), skill
# frontmatter, and relative links that do not resolve on disk.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PLUGIN_SCHEMA="https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
MCP_SCHEMA="https://agent-plugins.org/schemas/1.0.0/mcp.schema.json"
VALID_TYPES="stdio streamable-http sse"
FORBIDDEN_MCP_FIELDS="disabled autoApprove disabledTools oauth oauthScopes"

FAILURES=0
CHECKS=0

pass() { CHECKS=$((CHECKS + 1)); printf '  ok    %s\n' "$1"; }
fail() { CHECKS=$((CHECKS + 1)); FAILURES=$((FAILURES + 1)); printf '  FAIL  %s\n' "$1"; }

json_get() { python3 -c 'import json,sys;
d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    d = d.get(k) if isinstance(d, dict) else None
    if d is None: break
print("" if d is None else (d if isinstance(d,str) else json.dumps(d)))' "$1" "$2" 2>/dev/null; }

# --- JSON parses -----------------------------------------------------------
echo "JSON syntax"
while IFS= read -r f; do
	if python3 -c 'import json,sys;json.load(open(sys.argv[1]))' "$f" 2>/dev/null; then
		pass "$f parses"
	else
		fail "$f is not valid JSON"
	fi
done < <(find . -name '*.json' -o -name '*.kiro.hook' | grep -v '/\.git/' | sort)

# --- one plugin per directory ----------------------------------------------
PLUGINS=()
while IFS= read -r d; do PLUGINS+=("$d"); done < <(find plugins -mindepth 1 -maxdepth 1 -type d | sort)

if [ "${#PLUGINS[@]}" -eq 0 ]; then
	echo "No plugins found under plugins/" >&2
	exit 1
fi

for plugin_dir in "${PLUGINS[@]}"; do
	plugin_name="$(basename "$plugin_dir")"
	echo
	echo "Plugin: $plugin_name"

	manifest="$plugin_dir/plugin.json"
	if [ ! -f "$manifest" ]; then
		fail "$plugin_dir has no plugin.json"
		continue
	fi

	[ "$(json_get "$manifest" '$schema')" = "$PLUGIN_SCHEMA" ] &&
		pass "plugin.json \$schema targets 1.0.0" ||
		fail "plugin.json \$schema must be $PLUGIN_SCHEMA"

	name="$(json_get "$manifest" name)"
	[ "$name" = "$plugin_name" ] &&
		pass "plugin.json name matches its directory" ||
		fail "plugin.json name '$name' does not match directory '$plugin_name'"

	if printf '%s' "$name" | grep -qE '^[a-z0-9]([a-z0-9]|-(?!-)|\.(?!\.))*[a-z0-9]$' 2>/dev/null ||
		python3 -c 'import re,sys;n=sys.argv[1];sys.exit(0 if re.fullmatch(r"[a-z0-9][a-z0-9.-]{0,62}[a-z0-9]",n) and "--" not in n and ".." not in n else 1)' "$name"; then
		pass "name '$name' satisfies the naming rules"
	else
		fail "name '$name' breaks the naming rules (a-z 0-9 - . only, no -- or .., alphanumeric ends)"
	fi

	# Registry submission requires these on top of the spec's two.
	for field in version description license; do
		[ -n "$(json_get "$manifest" "$field")" ] &&
			pass "plugin.json has $field" ||
			fail "plugin.json is missing $field"
	done
	[ -n "$(json_get "$manifest" author.name)" ] &&
		pass "plugin.json has author.name" ||
		fail "plugin.json is missing author.name"
	[ -n "$(json_get "$manifest" keywords)" ] &&
		pass "plugin.json has keywords" ||
		fail "plugin.json is missing keywords"

	# --- mcp.json ----------------------------------------------------------
	mcp="$plugin_dir/mcp.json"
	if [ -f "$mcp" ]; then
		[ "$(json_get "$mcp" '$schema')" = "$MCP_SCHEMA" ] &&
			pass "mcp.json \$schema targets 1.0.0" ||
			fail "mcp.json \$schema must be $MCP_SCHEMA"

		servers="$(python3 -c 'import json,sys;print("\n".join(json.load(open(sys.argv[1])).get("mcpServers",{}).keys()))' "$mcp")"
		[ -n "$servers" ] &&
			pass "mcp.json declares at least one server" ||
			fail "mcp.json has no mcpServers entries"

		while IFS= read -r server; do
			[ -n "$server" ] || continue
			stype="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["mcpServers"][sys.argv[2]].get("type",""))' "$mcp" "$server")"
			if printf '%s' "$VALID_TYPES" | grep -qw -- "$stype"; then
				pass "server '$server' has type '$stype'"
			else
				fail "server '$server' has no valid type (got '$stype'; expected one of: $VALID_TYPES)"
			fi

			for field in $FORBIDDEN_MCP_FIELDS; do
				present="$(python3 -c 'import json,sys;print("yes" if sys.argv[3] in json.load(open(sys.argv[1]))["mcpServers"][sys.argv[2]] else "")' "$mcp" "$server" "$field")"
				[ -z "$present" ] ||
					fail "server '$server' carries '$field', which is not in the plugin format"
			done

			# ${VAR} is expanded only in args, env values and cwd — never in a
			# url or a header, so a placeholder there silently stays literal.
			leaked="$(python3 -c '
import json,sys,re
e=json.load(open(sys.argv[1]))["mcpServers"][sys.argv[2]]
bad=[]
if re.search(r"\$\{", e.get("url","") or ""): bad.append("url")
for k,v in (e.get("headers") or {}).items():
    if re.search(r"\$\{", str(v)) or re.search(r"\$\{", k): bad.append("headers."+k)
print(",".join(bad))' "$mcp" "$server")"
			[ -z "$leaked" ] &&
				pass "server '$server' has no unexpandable placeholders" ||
				fail "server '$server' uses \${...} in $leaked, which is never expanded"

			secret="$(python3 -c '
import json,sys,re
e=json.load(open(sys.argv[1]))["mcpServers"][sys.argv[2]]
h=e.get("headers") or {}
print("yes" if any(re.search(r"(?i)authorization|api[-_]?key|token", k) for k in h) else "")' "$mcp" "$server")"
			[ -z "$secret" ] &&
				pass "server '$server' carries no credential headers" ||
				fail "server '$server' puts a credential in headers; the spec forbids secrets there"
		done <<< "$servers"
	else
		pass "no mcp.json (optional)"
	fi

	# --- skills ------------------------------------------------------------
	if [ ! -d "$plugin_dir/skills" ]; then
		pass "no skills/ (optional)"
		continue
	fi

	while IFS= read -r skill_dir; do
		skill_name="$(basename "$skill_dir")"
		skill_md="$skill_dir/SKILL.md"

		if [ ! -f "$skill_md" ]; then
			fail "skills/$skill_name has no SKILL.md"
			continue
		fi

		result="$(python3 - "$skill_md" "$skill_name" <<'PY'
import sys, re
path, expected = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
lines = text.split("\n")
if not lines or lines[0].strip() != "---":
    print("no opening frontmatter delimiter"); sys.exit()
try:
    end = next(i for i, l in enumerate(lines[1:], start=1) if l.strip() == "---")
except StopIteration:
    print("no closing frontmatter delimiter"); sys.exit()
block = "\n".join(lines[1:end])

m = re.search(r'^name:\s*"?([^"\n]+?)"?\s*$', block, re.M)
if not m:
    print("frontmatter has no name"); sys.exit()
if m.group(1) != expected:
    print(f"name '{m.group(1)}' does not match directory '{expected}'"); sys.exit()

d = re.search(r'^description:\s*(.+?)(?=^\w+:|\Z)', block, re.M | re.S)
if not d:
    print("frontmatter has no description"); sys.exit()
desc = d.group(1).strip().strip('"').strip()
if not desc:
    print("description is empty"); sys.exit()
if len(desc) > 1024:
    print(f"description is {len(desc)} chars (max 1024)"); sys.exit()
print("")
PY
)"
		[ -z "$result" ] &&
			pass "skills/$skill_name frontmatter is valid" ||
			fail "skills/$skill_name: $result"
	done < <(find "$plugin_dir/skills" -mindepth 1 -maxdepth 1 -type d | sort)
done

# --- relative links resolve -------------------------------------------------
echo
echo "Relative links"
link_result="$(python3 - <<'PY'
import os, re, sys
bad = []
for root, dirs, files in os.walk("plugins"):
    for fn in files:
        if not fn.endswith(".md"):
            continue
        path = os.path.join(root, fn)
        text = open(path, encoding="utf-8").read()
        # Strip fenced code blocks so example paths are not treated as links.
        text = re.sub(r"```.*?```", "", text, flags=re.S)
        for m in re.finditer(r"\]\(([^)]+)\)", text):
            target = m.group(1).split("#")[0].strip()
            if not target or re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("//") or target.startswith("/"):
                continue
            resolved = os.path.normpath(os.path.join(root, target))
            if not os.path.exists(resolved):
                bad.append(f"{path} -> {target}")
print("\n".join(bad))
PY
)"
if [ -z "$link_result" ]; then
	pass "every relative markdown link resolves"
else
	while IFS= read -r line; do fail "broken link: $line"; done <<< "$link_result"
fi

# --- no legacy references ---------------------------------------------------
echo
echo "Legacy format"
legacy="$(grep -rlE 'POWER\.md|STEERING\.md|steering/' plugins README.md 2>/dev/null | sort || true)"
[ -z "$legacy" ] &&
	pass "nothing references POWER.md, STEERING.md, or steering/" ||
	while IFS= read -r f; do fail "$f still references the legacy power format"; done <<< "$legacy"

[ ! -e POWER.md ] &&
	pass "no POWER.md at the repo root" ||
	fail "POWER.md still exists at the repo root"

echo
if [ "$FAILURES" -eq 0 ]; then
	echo "All $CHECKS checks passed."
	exit 0
fi
echo "$FAILURES of $CHECKS checks failed."
exit 1
