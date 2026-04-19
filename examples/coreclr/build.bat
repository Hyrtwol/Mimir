@echo Executing: dotnet build .
dotnet build .
@echo Executing: odin run . -vet
odin run . -vet -collection:shared=C:\dev\odin\shared
@echo Done. %ERRORLEVEL%
