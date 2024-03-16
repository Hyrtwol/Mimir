@echo off

rem Title Visual Studio 2022 Command Prompt - %~n1
@call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
rem cd /d %1
@prompt "$P"$_$G

pushd command_line_tool

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

@echo # Resource Compiler> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
../../tools/ilasm /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

rem ilasm

@set OUTF=ildasm.md
@echo Generating %OUTF%

@echo # Resource Compiler> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
../../tools/ildasm /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

popd

rem Odin doc's
rem -short
rem -all-packages
rem -doc-format

@set OUTF=doc.txt
@echo Generating %OUTF%
odin doc . -collection:shared=..\\shared -all-packages -doc-format> %OUTF%

@echo Done.
