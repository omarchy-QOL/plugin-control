#!/bin/bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR
ROOT="$(cd -- "$TEST_DIR/.." && pwd)"
readonly ROOT

qmllint_bin="$(command -v qmllint)"
if [[ -x /usr/lib/qt6/bin/qmllint ]]; then
  qmllint_bin=/usr/lib/qt6/bin/qmllint
fi
"$qmllint_bin" -I /usr/share/omarchy/shell \
  "$ROOT/Service.qml" "$ROOT/PluginControl.qml" "$ROOT/ActionDialog.qml" \
  "$ROOT/PluginControlBar.qml" "$ROOT/SelfRemovalDialog.qml" \
  "$ROOT/PaletteResultRow.qml" "$ROOT/PaletteFooter.qml" \
  "$ROOT/PreviewCard.qml" \
  "$ROOT/lib/shortcuts/HyprlandBinding.qml"
printf 'ok - QML lint\n'

open_body="$(sed -n '/function open(payloadJson)/,/^  }/p' \
  "$ROOT/PluginControl.qml")"
if grep -Eq 'curl|git|requestRefresh' <<<"$open_body"; then
  printf 'not ok - open path performs network or Git work\n' >&2
  exit 1
fi
printf 'ok - overlay open path has no network or Git action\n'

shared_shortcuts="$ROOT/../oma-plug-dev-shared-shortcuts/shortcuts"
if [[ -d $shared_shortcuts ]]; then
  cmp -s "$ROOT/lib/shortcuts/ShortcutFormat.js" \
    "$shared_shortcuts/ShortcutFormat.js"
  cmp -s "$ROOT/lib/shortcuts/HyprlandBinding.qml" \
    "$shared_shortcuts/HyprlandBinding.qml"
  printf 'ok - shared shortcut library copies are current\n'
else
  printf 'ok - shared shortcut comparison skipped outside the monorepo\n'
fi

runtime_root="$(mktemp -d /tmp/plugin-control-qml-load.XXXXXX)"
trap 'rm -rf -- "$runtime_root"' EXIT
mkdir -p "$runtime_root/config" "$runtime_root/home" "$runtime_root/bin"
printf '#!/bin/sh\nprintf "pasted text\\nsecond line"\nexec yes\n' \
  >"$runtime_root/bin/wl-paste"
chmod +x "$runtime_root/bin/wl-paste"
cp "$TEST_DIR/fixtures/qml-entrypoints/shell.qml" \
  "$runtime_root/config/shell.qml"
ln -s /usr/share/omarchy/shell/Commons "$runtime_root/config/Commons"
ln -s /usr/share/omarchy/shell/Ui "$runtime_root/config/Ui"
if ! env QT_QPA_PLATFORM=wayland HOME="$runtime_root/home" \
  PATH="$runtime_root/bin:$PATH" \
  XDG_CONFIG_HOME="$runtime_root/config" \
  XDG_CACHE_HOME="$runtime_root/cache" \
  XDG_STATE_HOME="$runtime_root/state" \
  OMARCHY_PATH=/usr/share/omarchy PLUGIN_CONTROL_SOURCE_DIR="$ROOT" \
  QML2_IMPORT_PATH=/usr/share/omarchy/shell \
  QML_IMPORT_PATH=/usr/share/omarchy/shell \
  timeout 20 quickshell -p "$runtime_root/config" --no-color \
  >"$runtime_root/quickshell.log" 2>&1; then
  sed -n '1,240p' "$runtime_root/quickshell.log" >&2
  exit 1
fi
grep -Fq 'PLUGIN_CONTROL_LOAD_OK service' "$runtime_root/quickshell.log"
grep -Fq 'PLUGIN_CONTROL_LOAD_OK overlay' "$runtime_root/quickshell.log"
grep -Fq 'PLUGIN_CONTROL_LOAD_OK bar-widget' "$runtime_root/quickshell.log"
grep -Fq 'PLUGIN_CONTROL_WATCH_OK fresh install save' \
  "$runtime_root/quickshell.log"
grep -Fq 'PLUGIN_CONTROL_INTERACTION_OK palette interactions' \
  "$runtime_root/quickshell.log"
grep -Fq 'PLUGIN_CONTROL_SIDE_PREVIEW_OK delay selection and close' \
  "$runtime_root/quickshell.log"
grep -Fq 'PLUGIN_CONTROL_PASTE_OK capped single-line paste' \
  "$runtime_root/quickshell.log"
test -f "$runtime_root/config/omarchy/ilyazar.plugin-control/channels.yaml"
if grep -Fq 'PLUGIN_CONTROL_LOAD_ERROR' "$runtime_root/quickshell.log"; then
  sed -n '1,240p' "$runtime_root/quickshell.log" >&2
  exit 1
fi
printf 'ok - fresh install watcher and entry points instantiate in Quickshell\n'
