@echo off

setlocal EnableDelayedExpansion

if "%VSCMD_ARG_TGT_ARCH%"=="" call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

call build_shared.bat
if %errorlevel% neq 0 goto end_of_build

rem if %release_mode% EQU 0 odin run examples/demo -resource:%iconrc% -- Hellope World

del *.obj > NUL 2> NUL

:end_of_build
