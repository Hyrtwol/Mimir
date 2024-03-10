if "%VSCMD_ARG_TGT_ARCH%"=="" call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
set genconfig=Release
@rem msbuild gen.vcxproj /p:configuration=%config% /p:platform=x64
@rem goto generate
set genexe="x64\%genconfig%\gen.exe"
if exist %genexe% (
	del /f %genexe%
)
mkdir gen\x64\%genconfig% > NUL 2> NUL
cl /c /Zi /nologo /W3 /WX- /diagnostics:column /sdl /O2 /Oi /GL /D NDEBUG /D _CONSOLE /D _UNICODE /D UNICODE /Gm- /EHsc /MD /GS /Gy /fp:precise /Zc:wchar_t /Zc:forScope /Zc:inline /std:c++20 /permissive- /Fo"gen\x64\Release\\" /external:W3 /Gd /TP /FC /errorReport:queue gen.cpp
if %ERRORLEVEL% equ 0 (
	mkdir x64\%genconfig% > NUL 2> NUL
	link /ERRORREPORT:QUEUE /OUT:%genexe% /NOLOGO kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /MANIFEST /MANIFESTUAC:"level='asInvoker' uiAccess='false'" /manifest:embed /DEBUG /SUBSYSTEM:CONSOLE /OPT:REF /OPT:ICF /LTCG:incremental /LTCGOUT:"gen\x64\Release\gen.iobj" /TLBID:1 /DYNAMICBASE /NXCOMPAT /IMPLIB:"x64\Release\gen.lib" /MACHINE:X64 gen\x64\Release\gen.obj
)
:generate
if %ERRORLEVEL% equ 0 (
	%genexe% ..\test_windows_generated.odin
)
