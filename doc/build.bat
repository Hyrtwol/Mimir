@echo off

rem Title Visual Studio 2022 Command Prompt - %~n1
@call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
rem cd /d %1
@prompt "$P"$_$G

rem Odin

@set OUTF=odin_command_line_tool.md
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

@set OUTF=cl_command_line_tool.md
@echo Generating %OUTF%

@echo # C/C++ Compiler> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
@cl /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%

rem RC

@set OUTF=rc_command_line_tool.md
@echo Generating %OUTF%

@echo # Resource Compiler> %OUTF%
@echo.>> %OUTF%
@echo ```txt>> %OUTF%
@rc /?>> %OUTF%
@echo ```>> %OUTF%
@echo.>> %OUTF%
