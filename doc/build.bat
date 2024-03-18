@echo off

rem Title Visual Studio 2022 Command Prompt - %~n1
rem if "%VSCMD_ARG_TGT_ARCH%"=="" call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
if "%VSCMD_ARG_TGT_ARCH%"=="" call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
rem cd /d %1
@prompt "$P"$_$G

pushd command_line_tools
cd

rem Odin

@set OUTF=odin.md
@echo Generating %OUTF%

@echo # Odin> %OUTF%
@echo.>> %OUTF%
@odin version>> %OUTF%
@echo.>> %OUTF%

@echo ## Commands>> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
@odin help>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

@echo ## Build>> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
@odin help build>> %OUTF%
@echo ```>> %OUTF%

rem C/C++ Compiler

@set OUTF=cl.md
@echo Generating %OUTF%

@echo # C/C++ Compiler> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
@cl /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

rem RC

@set OUTF=rc.md
@echo Generating %OUTF%

@echo # Resource Compiler> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
@rc /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

rem ilasm

@set OUTF=ilasm.md
@echo Generating %OUTF%

@echo # ilasm> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
..\..\tools\ilasm /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

rem ildasm

@set OUTF=ildasm.md
@echo Generating %OUTF%

@echo # ildasm> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
..\..\tools\ildasm /?>> %OUTF%
@echo ```>> %OUTF%

rem nuget

@set OUTF=nuget.md
@echo Generating %OUTF%

@echo # nuget> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
..\..\tools\nuget help>> %OUTF%
@echo ```>> %OUTF%

popd

rem Odin doc's
rem -short
rem -all-packages
rem -doc-format

@set OUTF=doc.txt
@echo Generating %OUTF%
set doc_opt=-collection:shared=..\\shared
set doc_opt=%doc_opt% -all-packages
set doc_opt=%doc_opt% -doc-format
odin doc . %doc_opt%> %OUTF%

@echo Done.
