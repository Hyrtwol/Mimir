@echo off

rem call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"

if not exist "..\lib" mkdir ..\lib

rem cl -nologo -MT -O2 -c xatlas.cpp
cl -nologo -MT -O2 -c -DXATLAS_C_API=1 xatlas.cpp
lib -nologo xatlas.obj -out:xatlas.lib

del *.obj
