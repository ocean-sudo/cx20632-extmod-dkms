#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DKMS_CONF="${SCRIPT_DIR}/dkms.conf"
MODULE_NAME="snd_hda_codec_conexant"

if ! command -v dkms >/dev/null 2>&1; then
  echo "dkms command not found. Please install dkms first." >&2
  exit 1
fi

if [[ ! -f "${DKMS_CONF}" ]]; then
  echo "missing dkms.conf: ${DKMS_CONF}" >&2
  exit 1
fi

read_conf_value() {
  local key="$1"
  local value
  value="$(sed -n "s/^${key}=\"\(.*\)\"$/\1/p" "${DKMS_CONF}" | head -n1)"
  if [[ -z "${value}" ]]; then
    echo "failed to read ${key} from dkms.conf" >&2
    exit 1
  fi
  printf '%s\n' "${value}"
}

PACKAGE_NAME="$(read_conf_value PACKAGE_NAME)"
PACKAGE_VERSION="$(read_conf_value PACKAGE_VERSION)"

run_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

dkms_entry_exists() {
  dkms status -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" 2>/dev/null | grep -q "${PACKAGE_NAME}/${PACKAGE_VERSION}"
}

register_module_if_needed() {
  if dkms_entry_exists; then
    return
  fi
  run_root dkms add "${SCRIPT_DIR}"
}

reload_audio_stack() {
  run_root modprobe -r snd_hda_intel || true
  run_root modprobe -r "${MODULE_NAME}" || true
  run_root modprobe "${MODULE_NAME}" || true
  run_root modprobe snd_hda_intel || true
}

usage() {
  cat <<USAGE
Usage:
  ./dkms-manager.sh install [--reload]
  ./dkms-manager.sh remove [--reload]
  ./dkms-manager.sh reinstall [--reload]
  ./dkms-manager.sh status

Commands:
  install    Add/build/install module through DKMS
  remove     Remove this module version from DKMS
  reinstall  Remove then install again
  status     Show DKMS status for this module

Flags:
  --reload   Reload HDA modules immediately after action
USAGE
}

command="${1:-status}"
reload="false"
if [[ "${2:-}" == "--reload" || "${1:-}" == "--reload" ]]; then
  reload="true"
fi

case "${command}" in
  install)
    register_module_if_needed
    run_root dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
    run_root dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
    ;;
  remove)
    if dkms_entry_exists; then
      run_root dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all
    else
      echo "No DKMS entry found for ${PACKAGE_NAME}/${PACKAGE_VERSION}."
    fi
    ;;
  reinstall)
    if dkms_entry_exists; then
      run_root dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all || true
    fi
    register_module_if_needed
    run_root dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
    run_root dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}"
    ;;
  status)
    dkms status -m "${PACKAGE_NAME}" || true
    ;;
  help|-h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [[ "${reload}" == "true" ]]; then
  reload_audio_stack
fi

echo "Done: ${command} (${PACKAGE_NAME}/${PACKAGE_VERSION})"
