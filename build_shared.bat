@echo off

setlocal EnableDelayedExpansion

rem build the .lib files already exist

if not exist "shared\xatlas\*.lib" (
	pushd shared\xatlas
		call build.bat
	popd
)
