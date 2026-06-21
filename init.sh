#!/usr/bin/env bash
# shellcheck disable=SC2059
set -euo pipefail

REPO="${VIBE_ENV_INIT_REPO:-Miskamyasa/vibe-env-init}"
BRANCH="${VIBE_ENV_INIT_BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/templates"
ARCHIVE_URL="https://github.com/${REPO}/archive/${BRANCH}.tar.gz"

# ── Colors ──────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' DIM='\033[2m' NC='\033[0m'

info()  { printf "${B}i${NC}  %s\n" "$1"; }
ok()    { printf "${G}+${NC}  %s\n" "$1"; }
warn()  { printf "${Y}!${NC}  %s\n" "$1"; }
err()   { printf "${R}x${NC}  %s\n" "$1" >&2; }

# ── Cleanup trap ────────────────────────────────────────────────────
TMPDIR_INIT=""
cleanup() {
  if [[ -n "$TMPDIR_INIT" && -d "$TMPDIR_INIT" ]]; then
    rm -rf "$TMPDIR_INIT"
  fi
}
trap cleanup EXIT

# -- Arguments --------------------------------------------------------
RAW_PROJECT_NAME="${1:-$(basename "$PWD")}" 

sanitize_project_name() {
  local input="$1"
  local sanitized
  sanitized=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_.-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
  if [[ -z "$sanitized" ]]; then
    sanitized="project"
  fi
  printf '%s' "$sanitized"
}

PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
if [[ "$RAW_PROJECT_NAME" != "$PROJECT_NAME" ]]; then
  warn "Project name normalized for container compatibility: '${RAW_PROJECT_NAME}' -> '${PROJECT_NAME}'"
fi

# ── Helpers ─────────────────────────────────────────────────────────

fetch() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    err "Neither curl nor wget found"
    exit 1
  fi
}

fetch_template_tree() {
  TMPDIR_INIT="${TMPDIR_INIT:-$(create_tmpdir)}"

  local archive="${TMPDIR_INIT}/repo.tar.gz"
  local extract_dir="${TMPDIR_INIT}/repo"

  mkdir -p "$extract_dir"
  fetch "$ARCHIVE_URL" "$archive" || exit 1

  if ! command -v tar &>/dev/null; then
    err "tar not found"
    exit 1
  fi

  tar -xzf "$archive" -C "$extract_dir" --strip-components=1 || exit 1

  if [[ ! -d "${extract_dir}/templates" ]]; then
    err "Template directory not found in ${ARCHIVE_URL}"
    exit 1
  fi

  printf '%s' "${extract_dir}/templates"
}

prompt_mode() {
  echo ""
  printf "${C}Select opencode session mode:${NC}\n"
  echo ""
  printf "  ${B}1)${NC} shared  - Share opencode sessions between containers\n"
  printf "             Uses opencode v1.1.63 (pre-SQLite, session sharing compatible)\n"
  echo ""
  printf "  ${B}2)${NC} sqlite  - Isolated opencode data per project\n"
  printf "             Uses latest opencode (SQLite-based, no cross-container sessions)\n"
  echo ""

  while true; do
    printf "${C}Choose [1/2]:${NC} "
    read -r choice
    case "$choice" in
      1|shared)  MODE="shared"; break ;;
      2|sqlite)  MODE="sqlite"; break ;;
      *)         warn "Please enter 1 or 2" ;;
    esac
  done

  ok "Mode: ${MODE}"
  echo ""
}

escape_sed_replacement() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

create_tmpdir() {
  local tmp
  if tmp=$(mktemp -d 2>/dev/null); then
    printf '%s' "$tmp"
    return
  fi
  mktemp -d -t vibe-env-init
}

supports_diff_color() {
  diff --color=auto -u /dev/null /dev/null >/dev/null 2>&1
}

show_conflict() {
  local rel_path="$1" dest="$2" template_file="$3" template_label="$4"
  local escaped_project_name
  escaped_project_name="$(escape_sed_replacement "$PROJECT_NAME")"

  TMPDIR_INIT="${TMPDIR_INIT:-$(create_tmpdir)}"
  local tmp_file
  tmp_file="${TMPDIR_INIT}/$(basename "$rel_path")"

  cp "$template_file" "$tmp_file"

  # Apply template substitution to temp file for accurate diff
  if command -v sed &>/dev/null; then
    sed -i.bak "s|{{PROJECT_NAME}}|${escaped_project_name}|g" "$tmp_file" && rm -f "${tmp_file}.bak"
  fi

  if command -v diff &>/dev/null; then
    printf "\n${DIM}--- existing: %s${NC}\n" "$rel_path"
    printf "${DIM}+++ template: %s${NC}\n\n" "$template_label"
    if supports_diff_color; then
      diff --color=auto -u "$dest" "$tmp_file" || true
    else
      diff -u "$dest" "$tmp_file" || true
    fi
    echo ""
  fi

  printf "  ${DIM}Template: %s${NC}\n" "$template_label"
  info "Merge changes from the template manually if needed."
}

place_template_file() {
  local rel_path="$1" template_file="$2" template_label="$3"
  local dest="./${rel_path}"
  local dir
  dir=$(dirname "$dest")

  mkdir -p "$dir"

  if [[ -f "$dest" ]]; then
    warn "Exists, skipping: ${rel_path}"
    show_conflict "$rel_path" "$dest" "$template_file" "$template_label"
    return
  fi

  cp "$template_file" "$dest"
  ok "Created ${rel_path}"
}

apply_template() {
  local file="$1"
  local escaped_project_name
  escaped_project_name="$(escape_sed_replacement "$PROJECT_NAME")"
  if [[ -f "$file" ]]; then
    if command -v sed &>/dev/null; then
      sed -i.bak "s|{{PROJECT_NAME}}|${escaped_project_name}|g" "$file" && rm -f "${file}.bak"
    fi
  fi
}

destination_for_template() {
  local rel_path="$1"

  case "$rel_path" in
    mise.*.toml)
      if [[ "$rel_path" == "mise.${MODE}.toml" ]]; then
        printf '%s' "mise.toml"
      fi
      ;;
    .devcontainer/devcontainer.*.json)
      if [[ "$rel_path" == ".devcontainer/devcontainer.${MODE}.json" ]]; then
        printf '%s' ".devcontainer/devcontainer.json"
      fi
      ;;
    *)
      printf '%s' "$rel_path"
      ;;
  esac
}

copy_templates() {
  local templates_dir="$1"

  while IFS= read -r template_file; do
    local rel_path dest_path template_label
    rel_path="${template_file#"${templates_dir}/"}"
    dest_path="$(destination_for_template "$rel_path")"

    if [[ -z "$dest_path" ]]; then
      continue
    fi

    template_label="${BASE_URL}/${rel_path}"
    place_template_file "$dest_path" "$template_file" "$template_label"
    apply_template "$dest_path"
  done < <(find "$templates_dir" -type f | sort)
}

# ── Main ────────────────────────────────────────────────────────────

echo ""
printf "${B}+-----------------------------------------+${NC}\n"
printf "${B}|${NC}      vibe-env-init project scaffolder     ${B}|${NC}\n"
printf "${B}+-----------------------------------------+${NC}\n"
echo ""
info "Project name: ${PROJECT_NAME}"
info "Target dir:   $(pwd)"

# Prompt for mode
prompt_mode

# Download and copy every template file. Mode-specific templates are mapped to
# their final filenames, so new agents/commands/config files need no script edit.
TEMPLATES_DIR="$(fetch_template_tree)"
copy_templates "$TEMPLATES_DIR"

echo ""
ok "Done! Your dev environment is ready."
echo ""
info "Next steps:"
echo "   1. devcontainer up --workspace-folder .    # build & start the container"
echo "   2. devcontainer exec --workspace-folder . opencode   # run opencode inside it"
echo ""
info "Or use a wrapper script - see the README for details."
echo ""
