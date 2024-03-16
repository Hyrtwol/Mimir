@echo off

setlocal EnableDelayedExpansion

echo Cleaning root
del *.exe > NUL 2> NUL
del *.log > NUL 2> NUL
del hello.txt > NUL 2> NUL

echo Cleaning doc
del doc\*.res > NUL 2> NUL

echo Cleaning bin
del bin\*.txt > NUL 2> NUL
IF "%1" EQU "all" (
	del bin\*.exe > NUL 2> NUL
	del bin\*.pdb > NUL 2> NUL
)

:end_of_build
