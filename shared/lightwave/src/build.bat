@echo off

if "%VSCMD_ARG_TGT_ARCH%"=="" call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

rem /ifcOutput "win32\Debug\" /GS /TC /analyze- /W3 /Zc:wchar_t /I"..\..\..\include" /I"."
rem /ZI /Gm /Od /Fd"win32\Debug\vc143.pdb" /Zc:inline /fp:precise
rem /D "WIN32" /D "_MSWIN" /D "_DEBUG" /D "_WINDOWS" /D "_USRDLL" /D "_X86_" /D "_WIN32"
rem /errorReport:prompt /WX- /Zc:forScope /RTC1 /Gd /Oy- /MTd /FC /Fa"win32\Debug\" /EHsc /nologo /Fo"win32\Debug\" /Fp"win32\Debug\lwobject.pch" /diagnostics:column
rem D:\dev\lightwave\lwsdk\include
rem cl -nologo /TC -MT -O2 /I"D:\dev\lightwave\lwsdk\include" /I"." -c lwo2.c
rem set srcfiles=clip.c envelope.c list.c lwio.c lwo2.c lwob.c main.c pntspols.c surface.c vecmath.c vmap.c
rem set srcfiles=clip.c envelope.c list.c lwio.c lwo2.c lwob.c main.c pntspols.c surface.c vecmath.c vmap.c
set srcfiles=*.c
cl -nologo /TC -MT -O2 /I"D:\dev\lightwave\lwsdk\include" /I"." -D "_MSWIN" -c %srcfiles%
rem lib -nologo *.obj -out:..\lwo2.lib
lib *.obj -out:..\lwo2.lib -verbose

del *.obj
