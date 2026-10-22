@echo off
rem Update this repo from GitHub and copy Nothing Wasted into the WoW: Forever client.
rem Run it from anywhere (or double-click it), then restart the client, or /reload if Nothing
rem Wasted was already loaded. It only pulls what's on GitHub: push your commits first.
setlocal
rem The repo is the folder above this script's tools folder, so it keeps working if the repo is
rem renamed or moved.
for %%i in ("%~dp0..") do set "REPO=%%~fi"
rem Change WOW if your client lives elsewhere (for example a beta folder).
set "WOW=C:\Program Files (x86)\World of Warcraft\_forever_"
set "ADDON=%WOW%\Interface\AddOns\NothingWasted"

if not exist "%REPO%\NothingWasted\NothingWasted.toc" (
  echo Can't find the addon in %REPO%\NothingWasted. Is this script in the repo's tools folder?
  set "RESULT=1"
  goto done
)
if not exist "%WOW%\" (
  echo Can't find the WoW: Forever client at %WOW%. Fix WOW at the top of this script.
  set "RESULT=1"
  goto done
)

git -C "%REPO%" pull --ff-only
if errorlevel 1 (
  echo git pull failed, so nothing was copied.
  set "RESULT=1"
  goto done
)

rem First install: create the addon folder (and Interface\AddOns if the client has none yet).
if not exist "%ADDON%\" (
  echo Creating %ADDON%
  mkdir "%ADDON%"
  if errorlevel 1 (
    echo Couldn't create the folder. Is the WoW folder writable? Try running this as administrator.
    set "RESULT=1"
    goto done
  )
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
