@echo on
@set packages=packages
nuget install -ExcludeVersion -OutputDirectory %packages%

copy %packages%\runtime.win-x64.Microsoft.NETCore.ILAsm\runtimes\win-x64\native\ilasm.exe .
copy %packages%\runtime.win-x64.Microsoft.NETCore.ILDAsm\runtimes\win-x64\native\ildasm.exe .
