@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title RPE Automation Tool
color 0A

set "configFile=config.txt"

:: 1. Check if config.txt exists. If not, prompt user directly in CMD.
if not exist "%configFile%" (
    cls
    echo ====================================================
    echo             RPE AUTOMATION CONFIGURATION
    echo ====================================================
    echo.
    echo [INFO] config.txt not found. Please provide the required paths:
    echo.
    
    set /p "rpePath=rpe-launcher path : "
    set /p "wordExePath=WINWORD.exe path : "
    set /p "dsxDir=dsx directory : "
    set /p "macroName=macroNames : "
    set /p "wordOutDir=generatedbyRpeWordPATH : "
    
    :: Strip any accidental quotation marks from inputs
    set "rpePath=!rpePath:"=!"
    set "wordExePath=!wordExePath:"=!"
    set "dsxDir=!dsxDir:"=!"
    set "macroName=!macroName:"=!"
    set "wordOutDir=!wordOutDir:"=!"
    
    :: Save in your exact pattern format into config.txt
    (
        echo rpe-launcher path : !rpePath!
        echo WINWORD.exe path : !wordExePath!
        echo dsx directory : !dsxDir!
        echo macroNames : !macroName!
        echo generatedbyRpeWordPATH : !wordOutDir!
    ) > "%configFile%"
    
    echo.
    echo [SUCCESS] Configuration saved to config.txt!
    echo.
    pause
)

:: 2. Load configurations using a reliable line-by-line reading method
for /f "tokens=1,* delims=:" %%A in (%configFile%) do (
    set "key=%%A"
    set "val=%%B"
    
    :: Clean up extra spaces around the keys
    if "!key:~0,19!"=="rpe-launcher path " set "rpePath=!val:~1!"
    if "!key:~0,17!"=="WINWORD.exe path " set "wordExePath=!val:~1!"
    if "!key:~0,15!"=="dsx directory " set "dsxDir=!val:~1!"
    if "!key:~0,12!"=="macroNames " set "macroName=!val:~1!"
    if "!key:~0,26!"=="generatedbyRpeWordPATH " set "wordOutDir=!val:~1!"
)

:select_dsx
cls
echo ====================================================
echo              SELECT A .DSX FILE
echo ====================================================
echo.
echo DSX Directory: %dsxDir%
echo.
echo Available .dsx files:
echo ----------------------------------------------------

set "count=0"
for %%F in ("%dsxDir%\*.dsx") do (
    set /a count+=1
    set "dsxFile[!count!]=%%F"
    echo [!count!] %%~nxF
)

if %count%==0 (
    echo [ERROR] No .dsx files found in this directory!
    echo.
    pause
    exit
)

echo.
echo ----------------------------------------------------
set /p "selection=Enter the number of the DSX file you want to use: "

if not defined dsxFile[%selection%] (
    echo [ERROR] Invalid selection. Try again.
    pause
    goto select_dsx
)

set "dsx=!dsxFile[%selection%]!"
echo.
echo Selected: %dsx%
echo.
pause

:: --- EXECUTION PHASE ---

cls
echo ====================================================
echo Processing IBM, Please Wait..
echo ====================================================
start /wait "" "%rpePath%" -publish "%dsx%" -noresult

echo.
echo Waiting for RPE to finish writing the document...
timeout /t 10 /nobreak >nul

echo.
echo Finding latest generated Word document...

set "docx="
for /f "delims=" %%I in ('dir "%wordOutDir%\*.doc*" /a:-d /o:-d /b') do (
    set "docx=%wordOutDir%\%%I"
    set "docxName=%%~nxI"
    set "docxDate=%%~tI"
    goto found_file
)

:found_file
if not defined docx (
    echo [ERROR] No Word document found in the output directory: %wordOutDir%
    pause
    exit
)

echo ====================================================
echo LATEST GENERATED FILE FOUND:
echo Name : %docxName%
echo Date : %docxDate%
echo ====================================================
echo.

echo RPE generation complete. Now formatting Word document...
start "" "%wordExePath%" /t "%docx%" /m%macroName%

echo.
echo ====================================================
echo Task complete!
echo ====================================================
pause
exit