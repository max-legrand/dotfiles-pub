@echo off
REM Runs Ghostty with libghostty's own logging enabled. The log lands in
REM %LOCALAPPDATA%\ghostty\GhosttyWinUI.log (or the ghostty folder beside
REM this file, if you are using the portable config layout).
set GHOSTTY_LOG=stderr
start "" "%~dp0Ghostty-portable.exe"
