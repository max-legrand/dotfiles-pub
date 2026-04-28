#!/usr/bin/env bash
# Vendor every plugin from nvim-pack-lock.json into pack/vendor/start/.
# Also handles post-install artifacts:
#   - nvim-treesitter: compile parsers listed in scripts/ts-parsers.txt, then
#     copy the .so files into pack/vendor/start/nvim-treesitter/parser/.
# Run on a machine with internet. Commit the result.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCK_FILE="$NVIM_DIR/nvim-pack-lock.json"
VENDOR_DIR="$NVIM_DIR/pack/vendor/start"
PARSERS_LIST="$SCRIPT_DIR/ts-parsers.txt"

if [[ ! -f "$LOCK_FILE" ]]; then
	echo "lock file not found: $LOCK_FILE" >&2
	exit 1
fi
for cmd in jq nvim git; do
	if ! command -v "$cmd" >/dev/null; then
		echo "$cmd is required" >&2
		exit 1
	fi
done

# Run nvim with this repo as the config dir, so headless invocations
# pick up the vendored plugins regardless of $XDG_CONFIG_HOME on the host.
run_nvim() {
	env XDG_CONFIG_HOME="$(dirname "$NVIM_DIR")" nvim --headless "$@"
}

# ── 1. clone/refresh plugins ─────────────────────────────────────────────────
mkdir -p "$VENDOR_DIR"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

count=$(jq -r '.plugins | length' "$LOCK_FILE")
i=0
updated=0

while IFS=$'\t' read -r name src rev; do
	i=$((i + 1))
	target="$VENDOR_DIR/$name"
	printf '[%d/%d] %s @ %s\n' "$i" "$count" "$name" "${rev:0:7}"

	if [[ -f "$target/.vendor-rev" ]] && [[ "$(cat "$target/.vendor-rev")" == "$rev" ]]; then
		echo "  up to date"
		continue
	fi

	workdir="$tmp_root/$name"
	git clone --quiet "$src" "$workdir"
	git -C "$workdir" checkout --quiet "$rev"
	echo "$rev" >"$workdir/.vendor-rev"

	rm -rf "$workdir/.git"
	rm -rf "$target"
	mkdir -p "$(dirname "$target")"
	mv "$workdir" "$target"
	updated=$((updated + 1))
done < <(jq -r '.plugins | to_entries[] | "\(.key)\t\(.value.src)\t\(.value.rev)"' "$LOCK_FILE")

echo
echo "vendored $count plugins ($updated updated)"

# ── 2. compile + vendor treesitter parsers ───────────────────────────────────
if [[ -f "$PARSERS_LIST" ]]; then
	parsers=$(sed -e 's/#.*//' -e '/^\s*$/d' "$PARSERS_LIST" | tr '\n' ' ')
	if [[ -n "$parsers" ]]; then
		ts_target="$VENDOR_DIR/nvim-treesitter/parser"
		# Skip if every parser is already vendored.
		needs_install=0
		for parser in $parsers; do
			if [[ ! -f "$ts_target/$parser.so" ]]; then
				needs_install=1
				break
			fi
		done

		if [[ "$needs_install" == "1" ]]; then
			echo
			echo "==> compiling treesitter parsers: $parsers"

			if ! command -v tree-sitter >/dev/null; then
				echo "  ERROR: 'tree-sitter' CLI not found in PATH."
				echo "  Note: brew's 'tree-sitter' is the C library only."
				echo "  Install the CLI with one of:"
				echo "    brew install tree-sitter-cli"
				echo "    cargo install tree-sitter-cli"
				echo "    npm install -g tree-sitter-cli"
				exit 1
			fi

			# nvim-treesitter main branch: :TSInstall is async, drive install()
			# directly and pwait on the returned Task.
			ts_script="$tmp_root/install_parsers.lua"
			cat >"$ts_script" <<EOF
local parsers = vim.split([[$parsers]], "%s+", { trimempty = true })
local ok, install = pcall(require, "nvim-treesitter.install")
if not ok then
	io.stderr:write("nvim-treesitter not available\n")
	return
end
local task = install.install(parsers, { force = true, summary = true })
local success, err = task:pwait(600000)
if not success then
	io.stderr:write("install failed: " .. tostring(err) .. "\n")
end
EOF
			run_nvim -c "luafile $ts_script" -c 'qall!' 2>&1 | tail -20 || true

			mkdir -p "$ts_target"
			copied=0
			for src_dir in \
				"$HOME/.local/share/nvim/site/parser" \
				"$HOME/.local/share/nvim/parser"; do
				[[ -d "$src_dir" ]] || continue
				for so in "$src_dir"/*.so; do
					[[ -f "$so" ]] || continue
					cp -f "$so" "$ts_target/"
					copied=$((copied + 1))
				done
			done
			echo "  vendored $copied parser(s) into $ts_target"
		fi
	fi
else
	echo
	echo "(skip treesitter: create $PARSERS_LIST to enable)"
fi

# ── 3. strip dev/CI cruft and large media files ──────────────────────────────
# Plugins ship a lot Neovim never loads: CI configs, lockfiles, test fixtures,
# screenshots, READMEs. Removing them shrinks the vendored tree and keeps
# binary blobs out of the dotfiles repo.
echo
echo "==> stripping unused files"
size_before=$(du -sk "$VENDOR_DIR" | cut -f1)

# Directories to delete anywhere inside a plugin.
prune_dirs=(
	.github .gitlab .circleci
	tests test spec __tests__ benchmarks bench
	Examples examples
)

# Top-level files to delete from each plugin root.
top_files=(
	.editorconfig .gitignore .gitmodules .gitattributes
	.stylua.toml .styluaignore .luacheckrc .luarc.json
	_typos.toml typos.toml
	flake.nix flake.lock
	Cross.toml rust-toolchain.toml biome.json
	package.json package-lock.json bun.lock yarn.lock
	Makefile CMakeLists.txt
	README.md README.markdown README.rst README
	CHANGELOG.md CHANGELOG CHANGES.md
	CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md
	repro.lua
)

# Media extensions to delete anywhere except in target/release/ (where the
# vendored prebuilt binary metadata lives).
media_exts=(png jpg jpeg gif webp svg mp4 webm mov pdf)

for plugin_dir in "$VENDOR_DIR"/*/; do
	for d in "${prune_dirs[@]}"; do
		find "$plugin_dir" -type d -name "$d" -prune -exec rm -rf {} + 2>/dev/null || true
	done
	for f in "${top_files[@]}"; do
		[[ -e "$plugin_dir$f" ]] && rm -rf "$plugin_dir$f"
	done
	for ext in "${media_exts[@]}"; do
		find "$plugin_dir" -type f -name "*.$ext" \
			-not -path "*/target/release/*" \
			-delete 2>/dev/null || true
	done

	# Cargo leaves hundreds of MiB of intermediate artifacts under target/.
	# Only the prebuilt shared library (and its sidecars) are needed at runtime.
	if [[ -d "$plugin_dir/target" ]]; then
		find "$plugin_dir/target" -mindepth 1 -maxdepth 1 \
			-not -name release -exec rm -rf {} + 2>/dev/null || true
		if [[ -d "$plugin_dir/target/release" ]]; then
			find "$plugin_dir/target/release" -mindepth 1 \
				-not -name 'lib*.dylib' \
				-not -name 'lib*.so' \
				-not -name 'lib*.dll' \
				-not -name 'lib*.sha256' \
				-not -name 'version' \
				-exec rm -rf {} + 2>/dev/null || true
		fi
	fi
done

size_after=$(du -sk "$VENDOR_DIR" | cut -f1)
echo "  $size_before KiB → $size_after KiB"

# ── 4. write ATTRIBUTION.md ──────────────────────────────────────────────────
# Each vendored plugin is a third-party project under its own license. List
# them so the public repo carries the attribution required by MIT/Apache/etc.
echo
echo "==> writing ATTRIBUTION.md"

attribution="$NVIM_DIR/pack/vendor/ATTRIBUTION.md"

# Heuristically classify a license file by its content.
detect_license() {
	local file="$1"
	[[ -f "$file" ]] || { echo "Unknown"; return; }
	local body
	body=$(head -40 "$file")
	case "$body" in
		*"Apache License"*|*"apache.org/licenses/LICENSE-2.0"*) echo "Apache-2.0"; return;;
		*"Mozilla Public License"*) echo "MPL-2.0"; return;;
		*"GNU GENERAL PUBLIC LICENSE"*|*"GNU General Public License"*) echo "GPL"; return;;
		*"GNU LESSER"*|*"GNU Lesser General Public"*) echo "LGPL"; return;;
		*"BSD"*) echo "BSD"; return;;
		*"ISC License"*) echo "ISC"; return;;
		*"The Unlicense"*|*"unlicense.org"*) echo "Unlicense"; return;;
		*"Vim license"*) echo "Vim"; return;;
	esac
	# MIT signals: explicit header or canonical permission grant.
	if [[ "$body" == *"MIT License"* ]] || [[ "$body" == *"Permission is hereby granted, free of charge"* ]]; then
		echo "MIT"
		return
	fi
	echo "Unknown"
}

find_license_file() {
	local plugin_dir="$1"
	for candidate in LICENSE LICENSE.md LICENSE.txt LICENSE.rst COPYING COPYING.md License license.md; do
		if [[ -f "$plugin_dir/$candidate" ]]; then
			echo "$candidate"
			return
		fi
	done
}

{
	echo "# Vendored Plugin Attribution"
	echo
	echo "The plugins under \`pack/vendor/start/\` are third-party Neovim plugins"
	echo "vendored for air-gapped use. Each remains under its original copyright"
	echo "and license. License files are kept inside each plugin directory."
	echo
	echo "Auto-generated by \`scripts/sync-vendor.sh\` from \`nvim-pack-lock.json\`."
	echo
	echo "| Plugin | Source | Pinned Revision | License |"
	echo "|--------|--------|-----------------|---------|"

	while IFS=$'\t' read -r name src rev; do
		plugin_dir="$VENDOR_DIR/$name"
		short_rev="${rev:0:7}"
		# Strip trailing .git so the link goes to the repo browser.
		web_url="${src%.git}"
		commit_url="$web_url/commit/$rev"
		lic_file=$(find_license_file "$plugin_dir")
		if [[ -n "$lic_file" ]]; then
			lic_type=$(detect_license "$plugin_dir/$lic_file")
			lic_cell="[$lic_type](start/$name/$lic_file)"
		else
			lic_cell="see [$web_url]($web_url)"
		fi
		printf '| [%s](%s) | %s | [`%s`](%s) | %s |\n' \
			"$name" "$web_url" "$web_url" "$short_rev" "$commit_url" "$lic_cell"
	done < <(jq -r '.plugins | to_entries | sort_by(.key)[] | "\(.key)\t\(.value.src)\t\(.value.rev)"' "$LOCK_FILE")
} >"$attribution"

echo "  wrote $attribution"

echo
echo "done. next: git add nvim/pack/vendor && git commit"
echo
echo "note: prebuilt binaries (.dylib/.so) are >1 MiB; if jj refuses to snapshot"
echo "      them, run: jj config set --repo snapshot.max-new-file-size 8388608"
