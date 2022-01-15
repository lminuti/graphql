@ECHO OFF

:: Delphi 11 Alexandria
@SET "BDS=C:\Program Files (x86)\Embarcadero\Studio\22.0"

call "%BDS%\bin\rsvars.bat"
call GraphQL.Demos.Build.Common.bat

pause>nul