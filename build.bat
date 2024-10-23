@echo off

setlocal EnableDelayedExpansion

if "%VSCMD_ARG_TGT_ARCH%"=="" call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"

rem call build_shared.bat
rem if %errorlevel% neq 0 goto end_of_build
rem if %release_mode% EQU 0 odin run examples/demo -resource:%iconrc% -- Hellope World
rem del *.obj > NUL 2> NUL

msbuild build.recipe /l:FileLogger,Microsoft.Build.Engine;logfile=build.log

:end_of_build
