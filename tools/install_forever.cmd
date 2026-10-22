@echo off
rem Update this repo from GitHub and copy Nothing Wasted into the WoW: Forever client.
rem Run it from anywhere (or double-click it), then restart the client, or /reload if Nothing
rem Wasted was already loaded. It only pulls what's on GitHub: push your commits first.
setlocal
rem The repo is the folder this script is in, so it keeps working if the repo is renamed or moved.
set "REPO=%~dp0"
set "REPO=%REPO:~0,-1%"
rem Change this if your client lives elsewhere (for example a beta folder).
set "ADDON=C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\NothingWasted"

git -C "%REPO%" pull --ff-only
if errorlevel 1 (
  echo git pull failed, so nothing was copied.
  set "RESULT=1"
  goto done
)

rem /MIR makes the installed folder an exact copy (files no longer in the repo are deleted).
robocopy "%REPO%\NothingWasted" "%ADDON%" /MIR /IS /IT
rem robocopy exit codes below 8 mean success.
if errorlevel 8 (
  echo Copy failed. Is the WoW folder writable, and the path above right?
  set "RESULT=1"
  goto done
)

rem Stamp the installed copy with the commit, so /nw help shows which build is running.
rem "-dirty" means the copy includes changes that aren't committed.
for /f %%h in ('git -C "%REPO%" rev-parse --short HEAD') do set "BUILD=%%h"
for /f %%s in ('git -C "%REPO%" status --porcelain -- NothingWasted') do set "BUILD=%BUILD%-dirty"
> "%ADDON%\Build.lua" (
  echo local _, ns = ...
  echo ns.build = "%BUILD%"
)
echo Installed Nothing Wasted build %BUILD% into %ADDON%
echo In game: /reload, then /nw help should say build %BUILD%.
set "RESULT=0"

:done
rem Keep the window open when started by double-click.
echo %cmdcmdline% | find /i "%~nx0" >nul && pause
exit /b %RESULT%
