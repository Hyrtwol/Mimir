@echo off

setlocal EnableDelayedExpansion

echo Cleaning root
del *.exe > NUL 2> NUL
IF "%1" EQU "all" (
    echo Cleaning bin
    del bin\*.exe > NUL 2> NUL
    del bin\*.pdb > NUL 2> NUL
)

:end_of_build
