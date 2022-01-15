SET _TARGET=%1
IF [%1] == [] (SET _TARGET="Make")

SET _CONFIG=%2
IF [%2] == [] (SET _CONFIG="Debug")

SET _PLATFORM=%3
IF [%3] == [] (SET _PLATFORM="Win32")

SET BUILDTARGET="/t:%_TARGET%"
SET BUILDCONFIG="/p:config=%_CONFIG%"
SET BUILDPLATFORM="/p:platform=%_PLATFORM%"

SET "ERRORCOUNT=0"

@ECHO OFF

msbuild Main\MainDemo.dproj %BUILDTARGET% %BUILDCONFIG% %BUILDPLATFORM% 
IF %ERRORLEVEL% NEQ 0 set /a ERRORCOUNT+=1
msbuild PascalQuery\RttiQuery.dproj %BUILDTARGET% %BUILDCONFIG% %BUILDPLATFORM% 
IF %ERRORLEVEL% NEQ 0 set /a ERRORCOUNT+=1
msbuild Proxy\ProxyDemo.dproj %BUILDTARGET% %BUILDCONFIG% %BUILDPLATFORM% 
IF %ERRORLEVEL% NEQ 0 set /a ERRORCOUNT+=1


IF %ERRORCOUNT% NEQ 0 (
  
  ECHO ===========================================
  ECHO ===    %ERRORCOUNT% GraphQL Demos Failed to Compile   ===
  ECHO ===========================================  
  EXIT /B 1
  
) ELSE ( 

  ECHO ===========================================
  ECHO ===    GraphQL Demos Compiled Successful   ===
  ECHO ===========================================
  
)    

