@echo off
setlocal enabledelayedexpansion

set "ext=.d"
set "files="

for %%f in (*%ext%) do (
  if not defined files (
    set "files=%%f"
  ) else (
    set "files=!files! %%f"
  )
)

ldc2 -release -of=Liquid_v0_1.exe %files% && ^
move Liquid_v0_1.exe C:\neurocore\downloads\Arena\Engines

endlocal
