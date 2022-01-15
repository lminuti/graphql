@ECHO OFF

:: Delphi 10.2 Tokyo
@SET "BDS=C:\Program Files (x86)\Embarcadero\Studio\19.0"

call "%BDS%\bin\rsvars.bat"
call GraphQL.Demos.Build.Common.bat

pause>nul