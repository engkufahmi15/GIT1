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

:mode_selection
cls
echo ====================================================
echo             SELECT PROCESSING MODE
echo ====================================================
echo.
echo [1] Single File Mode (Choose one .dsx file)
echo [2] Multiple Mode (Choose multiple DSX files to loop through)
echo.
echo ----------------------------------------------------
set /p "modeChoice=Enter your choice (1 or 2): "

if "%modeChoice%"=="1" goto select_dsx
if "%modeChoice%"=="2" goto select_multiple_dsx

echo [ERROR] Invalid selection. Try again.
timeout /t 2 >nul
goto mode_selection


:select_dsx
cls
echo ====================================================
echo                SELECT A .DSX FILE
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

for %%Z in ("!dsxFile[%selection%]!") do set "dsx=%%~Z"

echo.
echo Selected: %dsx%
echo.
pause

call :run_pipeline
pause
exit


:select_multiple_dsx
cls
echo ====================================================
echo             SELECT MULTIPLE .DSX FILES
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
echo Example input: 1 3 4  (Separate numbers with spaces)
set /p "multiSelections=Enter the numbers of the DSX files you want to use: "

cls
echo ====================================================
echo          PROCESSING SELECTED .DSX FILES
echo ====================================================
echo.

:: Loop through the user's space-separated selections
for %%S in (%multiSelections%) do (
    if defined dsxFile[%%S] (
        for %%Z in ("!dsxFile[%%S]!") do set "dsx=%%~Z"
        echo ----------------------------------------------------
        echo Processing DSX [Selection %%S]: %%~nxZ
        echo ----------------------------------------------------
        call :run_pipeline
        echo.
    ) else (
        echo [WARNING] Selection '%%S' is invalid. Skipping...
        echo.
    )
)

echo ====================================================
echo All selected files processed!
echo ====================================================
pause
exit


:: --- SUBROUTINE: EXECUTION PIPELINE ---
:run_pipeline
cls
echo ====================================================
echo Processing IBM, Please Wait..
echo File: %dsx%
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
    goto :eof
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
echo Task complete for this file!
timeout /t 3 >nul
goto :eof