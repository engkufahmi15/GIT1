@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title RPE Automation Tool
color 0A

set "configFile=config5.txt"
set "rpePath="
set "wordExePath="
set "dsxDir="
set "macroName="
set "wordOutDir="

set "Repeat="
set "Index="

set /a Index=0
set /a Repeat=0

echo ====================================================
echo             RPE AUTOMATION CONFIGURATION
echo ====================================================
echo.
echo [Q1] checking %configFile% exist...

if not exist "%configFile%" (
    echo [A1] Not exist yet, Create new %configFile%
    echo.

    set /p "rpePath=[I] RPE_Launcher.EXE Path? "
    set /p "wordExePath=[II] WINWORD.EXE Path? "
    set /p "dsxDir=[III] DSX Directory Path? "
    set /p "macroName=[IV] Macro Names? "
    set /p "wordOutDir=[V] Word Output Path? "
    
    echo [1] RPE_Launcher.EXE="!rpePath!" > "%configFile%"
    echo [2] WINWORD.EXE="!wordExePath!" >> "%configFile%"
    echo [3] DSX_Directory="!dsxDir!" >> "%configFile%"
    echo [4] Macro_Name="!macroName!" >> "%configFile%"
    echo [5] WordOutput_Path="!wordOutDir!" >> "%configFile%"
    echo.
    echo.

) else (
    echo [A1] File %configFile% already exist
    echo.
    echo [Q2] Checking Whether Path Is Valid
    echo.

    for /f "tokens=1,* delims==" %%A in (%configFile%) do (
        set /a Index+=1
        set "key=%%A"
        set "val=%%B"
        
        :: Fetch Value From .txt
        if !Index! EQU 1 (
            if not "!val!"=="" (
                set "rpePath=!val!"
                echo !rpePath!
            )
        )

        if !Index! EQU 2 (
            if not "!val!"=="" (
                set "wordExePath=!val!"
                echo !wordExePath!
            )
        )

        if !Index! EQU 3 (
            if not "!val!"=="" (
                set "dsxDir=!val!"
                echo !dsxDir!
            )
        )

        if !Index! EQU 4 (
            if not "!val!"=="" (
                set "macroName=!val!"
                echo !macroName!
            )
        )

        if !Index! EQU 5 (
            if not "!val!"=="" (
                set "WordOutDir=!val!"
                echo !WordOutDir!
            )
        )
    )
    goto Exist_Check
)

pause
:: Check and ReWrite the path back to .txt file
:Exist_Check
if !Repeat! LSS 2 (
    set /a Repeat+=1

    if not exist "!rpePath!" (
        set /p "rpePath=[I] RPE_Launcher.EXE Cannot Be Found, New Path? "
        set /a Repeat=0
        goto Exist_Check
    )

    if not exist "!wordExePath!" (
        set /p "wordExePath=[II] WINWORD.EXE Cannot Be Found, New Path? "
        set /a Repeat=0
        goto Exist_Check
    )

    if not exist "!dsxDir!" (
        set /p "dsxDir=[III] DSX Directory Cannot Be Found, New Path? "
        set /a Repeat=0
        goto Exist_Check
    )

    if not exist "!wordOutDir!" (
        set /p "wordOutDir=[IV] Word Output Path Cannot Be Found, New Path? "
        set /a Repeat=0
        goto Exist_Check
    )
)

echo [A2] All the path are valid. Configuration saved to "%configFile%"!
echo.
:: Clean up any potential double quotes before saving
set "rpePath=!rpePath:"=!"
set "wordExePath=!wordExePath:"=!"
set "dsxDir=!dsxDir:"=!"
set "macroName=!macroName:"=!"
set "wordOutDir=!wordOutDir:"=!"

echo [1] RPE_Launcher.EXE="!rpePath!" > "%configFile%"
echo [2] WINWORD.EXE="!wordExePath!" >> "%configFile%"
echo [3] DSX_Directory="!dsxDir!" >> "%configFile%"
echo [4] Macro_Name="!macroName!" >> "%configFile%"
echo [5] WordOutDir="!wordOutDir!" >> "%configFile%"
echo.

:select_dsx
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