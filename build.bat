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

dmd -g -debug -color -of=Liquid_v0_1_d.exe %files% && Liquid_v0_1_d.exe

endlocal
