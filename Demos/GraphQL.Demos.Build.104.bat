@ECHO OFF

:: Delphi 10.4 Sydney
@SET "BDS=C:\Program Files (x86)\Embarcadero\Studio\21.0"

call "%BDS%\bin\rsvars.bat"
call GraphQL.Demos.Build.Common.bat

pause>nul