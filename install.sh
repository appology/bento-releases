#!/usr/bin/env bash
set -euo pipefail

# Bento install script
# Usage: curl -fsSL https://raw.githubusercontent.com/appology/bento/main/install.sh | bash

REPO="appology/bento-releases"
INSTALL_DIR="${BENTO_INSTALL_DIR:-/usr/local/bin}"
BINARY="bento"

info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33mwarning:\033[0m %s\n" "$*"; }
error() { printf "\033[1;31merror:\033[0m %s\n" "$*" >&2; exit 1; }

detect_platform() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  case "$OS" in
    linux)  OS="linux" ;;
    darwin) OS="darwin" ;;
    *)      error "Unsupported OS: $OS" ;;
  esac

  case "$ARCH" in
    x86_64|amd64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)             error "Unsupported architecture: $ARCH" ;;
  esac
}

latest_release() {
  if command -v curl &>/dev/null; then
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null
  elif command -v wget &>/dev/null; then
    wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null
  else
    return 1
  fi
}

download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL -o "$dest" "$url"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    error "Neither curl nor wget found"
  fi
}

install_from_release() {
  detect_platform

  info "Checking for latest release..."
  local release_json
  release_json="$(latest_release)" || return 1

  local tag
  tag="$(printf '%s' "$release_json" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"
  [ -z "$tag" ] && return 1

  # Try common archive naming patterns
  local asset_name="${BINARY}_${OS}_${ARCH}.tar.gz"
  local asset_url
  asset_url="$(printf '%s' "$release_json" | grep "browser_download_url" | grep "$asset_name" | head -1 | sed 's/.*"browser_download_url": *"//;s/".*//')"

  # Fallback: try without tar.gz (plain binary)
  if [ -z "$asset_url" ]; then
    asset_name="${BINARY}_${OS}_${ARCH}"
    asset_url="$(printf '%s' "$release_json" | grep "browser_download_url" | grep "$asset_name" | head -1 | sed 's/.*"browser_download_url": *"//;s/".*//')"
  fi

  [ -z "$asset_url" ] && return 1

  info "Downloading ${BINARY} ${tag} for ${OS}/${ARCH}..."
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  local downloaded="${tmpdir}/${asset_name}"
  download "$asset_url" "$downloaded"

  # Extract if archive, otherwise use directly
  if [[ "$asset_name" == *.tar.gz ]]; then
    tar -xzf "$downloaded" -C "$tmpdir"
    [ -f "${tmpdir}/${BINARY}" ] || error "Binary not found in archive"
  else
    mv "$downloaded" "${tmpdir}/${BINARY}"
  fi

  chmod +x "${tmpdir}/${BINARY}"
  install_binary "${tmpdir}/${BINARY}" "$tag"
}

install_from_go() {
  if ! command -v go &>/dev/null; then
    return 1
  fi

  info "Installing via go install..."
  go install "github.com/${REPO}@latest"

  local gobin
  gobin="$(go env GOBIN)"
  [ -z "$gobin" ] && gobin="$(go env GOPATH)/bin"

  if [ -x "${gobin}/${BINARY}" ]; then
    info "Installed to ${gobin}/${BINARY}"
    check_path "$gobin"
    return 0
  fi

  return 1
}

install_binary() {
  local src="$1" tag="${2:-}"

  if [ -w "$INSTALL_DIR" ]; then
    cp "$src" "${INSTALL_DIR}/${BINARY}"
  else
    info "Writing to ${INSTALL_DIR} requires sudo"
    sudo cp "$src" "${INSTALL_DIR}/${BINARY}"
  fi

  chmod +x "${INSTALL_DIR}/${BINARY}"
  info "Installed ${BINARY}${tag:+ ${tag}} to ${INSTALL_DIR}/${BINARY}"
  check_path "$INSTALL_DIR"
}

check_path() {
  local dir="$1"
  case ":$PATH:" in
    *":${dir}:"*) ;;
    *) warn "${dir} is not in your PATH. Add it to your shell profile." ;;
  esac
}

main() {
  info "Installing ${BINARY}..."
  echo

  # Try GitHub release first, fall back to go install
  if install_from_release 2>/dev/null; then
    echo
    info "Done! Run 'bento --help' to get started."
  elif install_from_go; then
    echo
    info "Done! Run 'bento --help' to get started."
  else
    echo
    error "Could not install bento. Install Go (https://go.dev) and run:
    go install github.com/${REPO}@latest"
  fi
}

main
