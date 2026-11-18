#!/usr/bin/env bash
# install-windows.sh - set up the Rex Windows config + AutoHotkey prefix from WSL.
#
#   rex/install-windows.sh            install/update, keep the live config.ini
#   rex/install-windows.sh --config   also overwrite the app's config.ini/palettes
#
# Installs:
#   %AppData%\rex\                     init.lua + helpers, rex-prefix.ahk,
#                                      rex-run.lua, rex-worker.lua
#   %LocalAppData%\Superlogical\Rex\   config.ini, palettes\ (only if missing,
#                                      or with --config: the app's Settings UI
#                                      writes to the live file, so it is often
#                                      newer than the repo)
#   Startup\rex-prefix.lnk             runs the AutoHotkey script at sign-in
# then reloads the Rex config and (re)starts the AutoHotkey script.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WITH_CONFIG=false
[[ ${1:-} == --config ]] && WITH_CONFIG=true

# Windows tools complain when started from a \\wsl$ working directory.
cd /mnt/c

winenv() { cmd.exe /c "echo %$1%" 2>/dev/null | tr -d '\r'; }
APPDATA_W=$(winenv APPDATA)
LOCALAPPDATA_W=$(winenv LOCALAPPDATA)
TEMP_W=$(winenv TEMP)
REX_DIR=$(wslpath "$APPDATA_W")/rex
APP_DIR=$(wslpath "$LOCALAPPDATA_W")/Superlogical/Rex
TMP=$(wslpath "$TEMP_W")
AHK_EXE='C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
AHK_SCRIPT="$APPDATA_W\\rex\\rex-prefix.ahk"
REX_EXE=$(wslpath "$LOCALAPPDATA_W")/Programs/Rex/rex.exe

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

ps() { # run a PowerShell script given on stdin
  local f="$TMP/rex-install-$$.ps1"
  cat > "$f"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$f")" | tr -d '\r'
  rm -f "$f"
}

# 1. AutoHotkey v2
if [[ ! -f $(wslpath "$AHK_EXE") ]]; then
  say "Installing AutoHotkey v2 (winget)"
  winget.exe install -e --id AutoHotkey.AutoHotkey \
    --accept-package-agreements --accept-source-agreements
fi

# 2. Rex config + AutoHotkey script
say "Copying Rex files to $APPDATA_W\\rex"
mkdir -p "$REX_DIR"
for f in init.lua rex-bell.lua tab-zoom.lua upper-labels.lua usgc-polyminimal2.conf \
         rex-run.lua rex-worker.lua rex-prefix.ahk; do
  cp "$HERE/$f" "$REX_DIR/$f"
done

# 3. App settings
mkdir -p "$APP_DIR/palettes"
if $WITH_CONFIG || [[ ! -f $APP_DIR/config.ini ]]; then
  say "Installing config.ini and palettes"
  cp "$HERE/config.ini" "$APP_DIR/config.ini"
  cp "$HERE"/palettes/*.ini "$APP_DIR/palettes/"
elif ! cmp -s "$HERE/config.ini" "$APP_DIR/config.ini"; then
  say "config.ini differs from the repo - left as is (use --config to overwrite)"
  echo "    diff: diff '$HERE/config.ini' '$APP_DIR/config.ini'"
fi

# 4. Validate the script before starting it
say "Validating rex-prefix.ahk"
"$(wslpath "$AHK_EXE")" /ErrorStdOut /validate "$AHK_SCRIPT"

# 5. Run at sign-in (call AutoHotkey directly, not via the .ahk association)
say "Creating Startup shortcut"
ps <<EOF
\$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'rex-prefix.lnk'
\$s = (New-Object -ComObject WScript.Shell).CreateShortcut(\$lnk)
\$s.TargetPath = '$AHK_EXE'
\$s.Arguments = '"$AHK_SCRIPT"'
\$s.WorkingDirectory = '$APPDATA_W\\rex'
\$s.Description = 'Rex Ctrl+Space prefix (dotfiles-pub/rex/rex-prefix.ahk)'
\$s.Save()
"    \$lnk"
EOF

# 6. Reload Rex's config
if [[ -x $REX_EXE ]]; then
  say "Reloading Rex config"
  "$REX_EXE" config reload >/dev/null && echo "    ok"
fi

# 7. (Re)start the script. Start-Process detaches it from this WSL shell, which
# would otherwise kill it on exit; #SingleInstance Force replaces a running copy.
say "Starting rex-prefix.ahk"
ps <<EOF
Start-Process -FilePath '$AHK_EXE' -ArgumentList '"$AHK_SCRIPT"'
Start-Sleep -Seconds 2
\$p = Get-CimInstance Win32_Process | Where-Object { \$_.Name -eq 'AutoHotkey64.exe' -and \$_.CommandLine -like '*rex-prefix.ahk*' }
"    running: \$(@(\$p).Count) instance(s)"
EOF
