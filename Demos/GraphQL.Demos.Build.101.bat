@ECHO OFF

:: Delphi 10.1 Berlin
@SET "BDS=C:\Program Files (x86)\Embarcadero\Studio\18.0"

call "%BDS%\bin\rsvars.bat"
call GraphQL.Demos.Build.Common.bat

pause>nul