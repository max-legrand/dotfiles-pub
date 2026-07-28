@echo off
REM Diagnostic: disables the renderer's damage tracking and rebuilds every
REM cell every frame. Slower, but it separates "drew the wrong thing" from
REM "was told nothing changed when something had".
set GHOSTTY_FORCE_FULL_REDRAW=1
set GHOSTTY_LOG=stderr
start "" "%~dp0Ghostty-portable.exe"
