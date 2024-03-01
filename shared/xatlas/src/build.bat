@echo off

if "%VSCMD_ARG_TGT_ARCH%"=="" call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

rem NDEBUG;XATLAS_C_API=1;XATLAS_EXPORT_API=1;_HAS_EXCEPTIONS=0;%(PreprocessorDefinitions)
cl -nologo -MT -O2 -c -DXATLAS_C_API=1 -D_HAS_EXCEPTIONS=0 -DXATLAS_API= xatlas.cpp
lib -nologo xatlas.obj -out:..\xatlas.lib

del *.obj
