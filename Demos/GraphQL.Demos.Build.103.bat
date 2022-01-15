@ECHO OFF

:: Delphi 10.3 Rio
@SET "BDS=C:\Program Files (x86)\Embarcadero\Studio\20.0"

call "%BDS%\bin\rsvars.bat"
call GraphQL.Demos.Build.Common.bat

pause>nul