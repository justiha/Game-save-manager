@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: Clear out lingering variables so a deleted config forces a true fresh start
set "GAME_NAME="
set "SAVE_PATH="
set "WORKSPACE="
set "ACTIVE_PROFILE="
set "PROFILE_COLOR="

set "CONFIG_FILE=%~dp0config.txt"

if not exist "%CONFIG_FILE%" goto SETUP_STEAM

for /f "usebackq delims=" %%I in ("%CONFIG_FILE%") do set "%%I"

:: Fallback if PROFILE_COLOR isn't set in older configs
if "%PROFILE_COLOR%"=="" set "PROFILE_COLOR=96"
goto SPLASH_SCREEN

:SETUP_STEAM
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 STEAM AUTO-DISCOVERY SETUP WIZARD" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
echo Would you like to setup Steam to automatically find your saves?
echo.
echo   [1] Yes - Auto-scan for Steam / userdata
echo   [2] No - Skip Steam setup
echo.
set "steam_choice="
set /p "steam_choice=Select option (1 or 2): "

if "%steam_choice%"=="2" goto SKIP_STEAM
if /i "%steam_choice%"=="no" goto SKIP_STEAM

:: =================================================================
:: PHASE 1: STEAM BASE DISCOVERY (C: Drive + Drive Letter Fallback)
:: =================================================================
echo.
call :COLOR_TEXT "[*] Scanning default C: drive locations..." "WHITE"

set "FOUND_STEAM="

if exist "C:\Program Files (x86)\Steam\userdata" (
    set "FOUND_STEAM=C:\Program Files (x86)\Steam"
    goto PROCESS_STEAM_FOUND
)
if exist "C:\Program Files\Steam\userdata" (
    set "FOUND_STEAM=C:\Program Files\Steam"
    goto PROCESS_STEAM_FOUND
)
if exist "C:\ProgramData\Steam\userdata" (
    set "FOUND_STEAM=C:\ProgramData\Steam"
    goto PROCESS_STEAM_FOUND
)

call :COLOR_TEXT "[!] Default C: drive locations yielded no Steam userdata folder." "YELLOW"
echo.
set "target_drive="
set /p "target_drive=Please enter your Steam drive letter (e.g., D, E, F): "

if "%target_drive%"=="" goto SKIP_STEAM

set "target_drive=%target_drive:~0,1%"
echo [*] Searching %target_drive%:\ for Steam installations...

if exist "%target_drive%:\Steam\userdata" (
    set "FOUND_STEAM=%target_drive%:\Steam"
    goto PROCESS_STEAM_FOUND
)
if exist "%target_drive%:\Program Files (x86)\Steam\userdata" (
    set "FOUND_STEAM=%target_drive%:\Program Files (x86)\Steam"
    goto PROCESS_STEAM_FOUND
)
if exist "%target_drive%:\Program Files\Steam\userdata" (
    set "FOUND_STEAM=%target_drive%:\Program Files\Steam"
    goto PROCESS_STEAM_FOUND
)

call :COLOR_TEXT "[!] Could not locate Steam on %target_drive%:\ drive. Skipping." "RED"
goto SKIP_STEAM

:PROCESS_STEAM_FOUND
set "STEAM_USERDATA_PATH=%FOUND_STEAM%\userdata"
call :COLOR_TEXT "[+] Locked in Steam userdata path: %STEAM_USERDATA_PATH%" "GREEN"
echo.

:: =================================================================
:: PHASE 2: STEAM ACCOUNT SELECTION
:: =================================================================
call :COLOR_TEXT "[*] Scanning for Steam User ID accounts..." "WHITE"
echo.

set "account_count=0"
for /d %%A in ("%STEAM_USERDATA_PATH%\*") do (
    set /a account_count+=1
    set "steam_account[!account_count!]=%%~nxA"
    
    set "game_count=0"
    for /d %%G in ("%%~fA\*") do set /a game_count+=1
    
    echo   [!account_count!] Account ID: %%~nxA  ^(Contains !game_count! game folders^)
)

if %account_count% EQU 0 (
    call :COLOR_TEXT "[!] No Steam ID accounts found. Skipping." "RED"
    goto SKIP_STEAM
)

if %account_count% EQU 1 (
    set "SELECTED_STEAM_ID=!steam_account[1]!"
    call :COLOR_TEXT "[+] Auto-selected sole account ID: !SELECTED_STEAM_ID!" "GREEN"
) else (
    echo.
    set "acc_select="
    set /p "acc_select=Select account number (Default is #3): "
    if "!acc_select!"=="" (
        set "SELECTED_STEAM_ID=139563194"
    ) else if defined steam_account[%acc_select%] (
        for %%X in (!acc_select!) do set "SELECTED_STEAM_ID=!steam_account[%%X]!"
    ) else (
        set "SELECTED_STEAM_ID=139563194"
    )
)

set "ACTIVE_ACCOUNT_DIR=%STEAM_USERDATA_PATH%\%SELECTED_STEAM_ID%"
call :COLOR_TEXT "[+] Active Account Directory set to: %SELECTED_STEAM_ID%" "GREEN"

:: Save choices to your main config file
(
    echo STEAM_USERDATA_PATH=%STEAM_USERDATA_PATH%
    echo SELECTED_STEAM_ID=%SELECTED_STEAM_ID%
    echo STEAM_SETUP_COMPLETE=YES
) >> "%CONFIG_FILE%"

echo.
call :COLOR_TEXT "[+] Steam setup configuration saved successfully!" "GREEN"
goto STEAM_SETUP_DONE

:SKIP_STEAM
echo.
call :COLOR_TEXT "[-] Steam setup skipped." "YELLOW"
(
    echo STEAM_SETUP_COMPLETE=NO
) >> "%CONFIG_FILE%"

:STEAM_SETUP_DONE
echo.
pause
goto RUN_SETUP_ROUTINE

:: =================================================================
:: SETUP & AUTO-DISCOVERY WIZARD
:: =================================================================
:RUN_SETUP_ROUTINE
cls
set "PROFILE_COLOR=96"
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "          MASTER SAVE MANAGER: SETUP WIZARD" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Enter a game keyword, or type [M] for a complete list of supported games:
echo   (e.g.hunter, chaos, blacklist, wd1, wd2, fc5, fc6, acv, aco, skyrim, etc.)
echo.
set "INPUT_GAME="
set /p "INPUT_GAME=Game Name / Keyword (or M): "

:: Check if user typed M for the full list
if /i "%INPUT_GAME%"=="M" goto SHOW_SUPPORTED_LIST

:: 1. The Hunter
echo "!INPUT_GAME!" | findstr /i "hunter" >nul
if errorlevel 1 goto Skyrim
set "GAME_NAME=The Hunter Call Of The Wild"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Avalanche Studios" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Avalanche Studios"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Avalanche Studios"
)

call :COLOR_TEXT "[+] Keyword matched: The Hunter: Call of the Wild" "GREEN"
goto FINALIZE_GAME_SETUP

:Skyrim
:: Skyrim
echo "!INPUT_GAME!" | findstr /i "Skyrimse" >nul
if errorlevel 1 goto Fallout4
set "GAME_NAME=Skyrim Special Edition"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\Skyrim Special Edition" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Skyrim Special Edition"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Skyrim Special Edition"
)

call :COLOR_TEXT "[+] Keyword matched: SKYRIM SE" "GREEN"
goto FINALIZE_GAME_SETUP

:Fallout4
:: Fallout 4
echo "!INPUT_GAME!" | findstr /i "Fo4" >nul
if errorlevel 1 goto AmericanTruckSimulator
set "GAME_NAME=Fallout 4"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\Fallout4" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Fallout4"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Fallout4"
)

call :COLOR_TEXT "[+] Keyword matched: Fallout 4" "GREEN"
goto FINALIZE_GAME_SETUP

:AmericanTruckSimulator
:: American Truck Simulator
echo "!INPUT_GAME!" | findstr /i "ats" >nul
if errorlevel 1 goto TheSims4
set "GAME_NAME=American Truck Simulator"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\American Truck Simulator" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\American Truck Simulator"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\American Truck Simulator"
)

call :COLOR_TEXT "[+] Keyword matched: American Truck Simulator" "GREEN"
goto FINALIZE_GAME_SETUP

:TheSims4
:: The Sims 4
echo "!INPUT_GAME!" | findstr /i "ts4" >nul
if errorlevel 1 goto EuroTruckSimulator2
set "GAME_NAME=The Sims 4"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Electronic Arts\The Sims 4" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Electronic Arts\The Sims 4"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Electronic Arts\The Sims 4"
)

call :COLOR_TEXT "[+] Keyword matched: The Sims 4" "GREEN"
goto FINALIZE_GAME_SETUP

:EuroTruckSimulator2
:: Euro Truck Simulator 2
echo "!INPUT_GAME!" | findstr /i "ets2" >nul
if errorlevel 1 goto HitmanBloodMoney
set "GAME_NAME=Euro Truck Simulator 2"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Euro Truck Simulator 2" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Euro Truck Simulator 2"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Euro Truck Simulator 2"
)

call :COLOR_TEXT "[+] Keyword matched: Euro Truck Simulator 2" "GREEN"
goto FINALIZE_GAME_SETUP

:HitmanBloodMoney
:: Hitman Blood Money
echo "!INPUT_GAME!" | findstr /i "hitmanbm" >nul
if errorlevel 1 goto HogwartsLegacy
set "GAME_NAME=Hitman Blood Money"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Hitman Blood Money" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Hitman Blood Money"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Hitman Blood Money"
)

call :COLOR_TEXT "[+] Keyword matched: Hitman Blood Money" "GREEN"
goto FINALIZE_GAME_SETUP

:HogwartsLegacy
:: Hogwarts Legacy
echo "!INPUT_GAME!" | findstr /i "hwl" >nul
if errorlevel 1 goto HorizonZeroDawn
set "GAME_NAME=Hogwarts Legacy"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Hogwarts Legacy" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Hogwarts Legacy"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Hogwarts Legacy"
)

call :COLOR_TEXT "[+] Keyword matched: Hogwarts Legacy (mods)" "GREEN"
goto FINALIZE_GAME_SETUP

:HorizonZeroDawn
:: Horizon Zero Dawn
echo "!INPUT_GAME!" | findstr /i "hzd" >nul
if errorlevel 1 goto inZOI
set "GAME_NAME=Horizon Zero Dawn"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Horizon Zero Dawn" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Horizon Zero Dawn"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Horizon Zero Dawn"
)

call :COLOR_TEXT "[+] Keyword matched: Horizon Zero Dawn" "GREEN"
goto FINALIZE_GAME_SETUP

:inZOI
:: inZOI
echo "!INPUT_GAME!" | findstr /i "inzoi" >nul
if errorlevel 1 goto Marvels_Avengers
set "GAME_NAME=inZOI"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\inZOI" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\inZOI"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\inZOI"
)

call :COLOR_TEXT "[+] Keyword matched: inZOI" "GREEN"
goto FINALIZE_GAME_SETUP

:Marvels_Avengers
:: Marvel's Avengers
echo "!INPUT_GAME!" | findstr /i "avengers" >nul
if errorlevel 1 goto Marvels_Spider_Man_Remastered
set "GAME_NAME=Marvels Avengers"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Marvel's Avengers" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Marvel's Avengers"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Marvel's Avengers"
)

call :COLOR_TEXT "[+] Keyword matched: Marvel's Avengers" "GREEN"
goto FINALIZE_GAME_SETUP

:Marvels_Spider_Man_Remastered
:: Marvel's Spider-Man Remastered
echo "!INPUT_GAME!" | findstr /i "smr" >nul
if errorlevel 1 goto A_Way_Out
set "GAME_NAME=Spider Man Remastered"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Marvel's Spider-Man Remastered" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Marvel's Spider-Man Remastered"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Marvel's Spider-Man Remastered"
)

call :COLOR_TEXT "[+] Keyword matched: Marvel's Spider-Man Remastered" "GREEN"
goto FINALIZE_GAME_SETUP

:A_Way_Out
:: A Way Out
echo "!INPUT_GAME!" | findstr /i "awayout" >nul
if errorlevel 1 goto Fallout_New_Vegas
set "GAME_NAME=A Way Out"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\A Way Out\Saves" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\A Way Out\Saves"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\A Way Out\Saves"
)

call :COLOR_TEXT "[+] Keyword matched: A Way Out" "GREEN"
goto FINALIZE_GAME_SETUP

:Fallout_New_Vegas
:: Fallout: New Vegas
echo "!INPUT_GAME!" | findstr /i "fonv" >nul
if errorlevel 1 goto Far_Cry_New_Dawn
set "GAME_NAME=Fallout New Vegas"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\FalloutNV" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\FalloutNV"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\FalloutNV"
)

call :COLOR_TEXT "[+] Keyword matched: Fallout: New Vegas" "GREEN"
goto FINALIZE_GAME_SETUP

:Far_Cry_New_Dawn
:: Far Cry New Dawn
echo "!INPUT_GAME!" | findstr /i "fcnd" >nul
if errorlevel 1 goto Life_Is_Strange
set "GAME_NAME=Far Cry New Dawn"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\Far Cry New Dawn" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Far Cry New Dawn"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Far Cry New Dawn"
)

call :COLOR_TEXT "[+] Keyword matched: Far Cry New Dawn" "GREEN"
goto FINALIZE_GAME_SETUP

:Life_Is_Strange
:: Life Is Strange
echo "!INPUT_GAME!" | findstr /i "lis1" >nul
if errorlevel 1 goto Life_Is_Strange_3
set "GAME_NAME=Life Is Strange"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\Life Is Strange\Saves" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Life Is Strange\Saves"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Life Is Strange\Saves"
)

call :COLOR_TEXT "[+] Keyword matched: Life Is Strange" "GREEN"
goto FINALIZE_GAME_SETUP

:Life_Is_Strange_3
:: Life Is Strange 3
echo "!INPUT_GAME!" | findstr /i "lis3" >nul
if errorlevel 1 goto Life_Is_Strange_Double_Exposure
set "GAME_NAME=Life Is Strange 3"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\LifeIsStrange3\Steam" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\LifeIsStrange3\Steam"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\LifeIsStrange3\Steam"
)

call :COLOR_TEXT "[+] Keyword matched: Life Is Strange 3" "GREEN"
goto FINALIZE_GAME_SETUP

:Life_Is_Strange_Double_Exposure
:: Life Is Strange: Double Exposure
echo "!INPUT_GAME!" | findstr /i "lisde" >nul
if errorlevel 1 goto Beyond_Two_Souls
set "GAME_NAME=Life Is Strange Double Exposure"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\LifeIsStrangeDoubleExposure\Steam\Saved" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\LifeIsStrangeDoubleExposure\Steam\Saved"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\My Games\LifeIsStrangeDoubleExposure\Steam\Saved"
)

call :COLOR_TEXT "[+] Keyword matched: Life Is Strange DE" "GREEN"
goto FINALIZE_GAME_SETUP

:Beyond_Two_Souls
:: Beyond: Two Souls
echo "!INPUT_GAME!" | findstr /i "bts" >nul
if errorlevel 1 goto Red_Dead_Redemption
set "GAME_NAME=Beyond Two Souls"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Quantic Dream\Beyond Two Souls\Save" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Quantic Dream\Beyond Two Souls\Save"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Quantic Dream\Beyond Two Souls\Save"
)

call :COLOR_TEXT "[+] Keyword matched: Beyond: Two Souls" "GREEN"
goto FINALIZE_GAME_SETUP

:Red_Dead_Redemption
:: Red Dead Redemption 2
echo "!INPUT_GAME!" | findstr /i "rdr2" >nul
if errorlevel 1 goto The_Walking_Dead
set "GAME_NAME=Red Dead Redemption 2"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Rockstar Games\Red Dead Redemption 2" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Rockstar Games\Red Dead Redemption 2"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Rockstar Games\Red Dead Redemption 2"
)

call :COLOR_TEXT "[+] Keyword matched: Red Dead Redemption 2" "GREEN"
goto FINALIZE_GAME_SETUP

:The_Walking_Dead
:: The Walking Dead
echo "!INPUT_GAME!" | findstr /i "twd" >nul
if errorlevel 1 goto The_Witcher
set "GAME_NAME=The Walking Dead"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Telltale Games\The Walking Dead" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Telltale Games\The Walking Dead"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Telltale Games\The Walking Dead"
)

call :COLOR_TEXT "[+] Keyword matched: The Walking Dead" "GREEN"
goto FINALIZE_GAME_SETUP

:The_Witcher
:: The Witcher 3
echo "!INPUT_GAME!" | findstr /i "tw3" >nul
if errorlevel 1 goto Tomb_Raider
set "GAME_NAME=The Witcher 3"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\The Witcher 3" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\The Witcher 3"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\The Witcher 3"
)

call :COLOR_TEXT "[+] Keyword matched: The Witcher 3" "GREEN"
goto FINALIZE_GAME_SETUP

:Tomb_Raider
:: Tomb Raider (2013)
echo "!INPUT_GAME!" | findstr /i "tr13" >nul
if errorlevel 1 goto Batman
set "GAME_NAME=Tomb Raider (2013)"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\Tomb Raider" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Tomb Raider"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\Tomb Raider"
)

call :COLOR_TEXT "[+] Keyword matched: Tomb Raider (2013)" "GREEN"
goto FINALIZE_GAME_SETUP

:Batman
:: Batman Arkham Knight (WB Games)
echo "!INPUT_GAME!" | findstr /i "bak" >nul
if errorlevel 1 goto CHECK_CHAOS
set "GAME_NAME=Batman Arkham Knight"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\WB Games" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\WB Games"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\WB Games"
)

call :COLOR_TEXT "[+] Keyword matched: Batman Arkham Knight" "GREEN"
goto FINALIZE_GAME_SETUP

:CHECK_CHAOS
:: 2. Splinter Cell: Chaos Theory (Steam / PC Version)
echo "!INPUT_GAME!" | findstr /i "scct" >nul
if errorlevel 1 goto CHECK_UBI
set "GAME_NAME=Splinter Cell Chaos Theory"

:: Check if the Documents save path exists, otherwise fall back to ProgramData
if exist "%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory" (
    set "SAVE_PATH=%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
) else (
    set "SAVE_PATH=C:\ProgramData\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
)

call :COLOR_TEXT "[+] Keyword matched: Splinter Cell Chaos Theory" "GREEN"
goto FINALIZE_GAME_SETUP

:SHOW_SUPPORTED_LIST
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "          COMPLETE LIST OF SUPPORTED AUTO-SCAN GAMES" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo [DOCUMENTS / DUAL-PATH GAMES]
echo   - Skyrim Special Edition / [skyrimse]
echo   - Fallout 4 / [fo4]
echo   - American Truck Simulator / [ats]
echo   - The Sims 4 / [ts4]
echo   - Euro Truck Simulator 2 / [ets2]
echo   - Hitman Blood Money / [hitmanbm]
echo   - Hogwarts Legacy (mods) / [hwl]
echo   - Horizon Zero Dawn / [hzd]
echo   - The Hunter (Call of the Wild) / [hunter]
echo   - inZOI / [inzoi]
echo   - Marvel's Avengers / [avengers]
echo   - Marvel's Spider-Man Remastered / [smr]
echo   - A Way Out / [awayout]
echo   - Fallout: New Vegas / [fonv]
echo   - Far Cry New Dawn / [fcnd]
echo   - Life Is Strange 1 / [lis1]
echo   - Life Is Strange 3 / [lis3]
echo   - Life Is Strange: Double Exposure / [lisde]
echo   - Beyond: Two Souls / [bts]
echo   - Red Dead Redemption 2 / [rdr2]
echo   - The Walking Dead / [twd]
echo   - The Witcher 3 / [tw3]
echo   - Tomb Raider (2013) / [tr13]
echo   - Batman Arkham Knight / [bak]
echo.
echo [UBISOFT GAMES]
echo   - Splinter Cell Blacklist / [blacklist]
echo   - Watch Dogs 1 / [wd1]
echo   - Watch Dogs 2 / [wd2]
echo   - Watch Dogs Legion / [wdl]
echo   - Far Cry 5 / [fc5]
echo   - Far Cry 6 / [fc6]
echo   - Assassin's Creed Valhalla / [acv]
echo   - Assassin's Creed Odyssey / [aco]
echo   - Assassin's Creed Origins / [ori]
echo   - Tom Clancy's The Division 2 / [div2]
echo   - Tom Clancy's Ghost Recon Wildlands / [grw]
echo.
echo [MANUAL / OTHER]
echo   - Splinter Cell: Chaos Theory (Steam / PC Version) / [scct]
echo   - (Type any custom name for manual path input)
echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo  [TIP] Know your game^? Just type its keyword (e.g., fo4, ets2, scct) 
echo        at the new game prompt screen to map it instantly.
echo.
echo        Don't see your game? No problem! This script is completely 
echo        universal—you can type any custom game name and provide 
echo        its save path manually.
call :COLOR_TEXT "=================================================================" "THEME"
pause
goto RUN_SETUP_ROUTINE

:CHECK_UBI
:: --- EXPANDED UBISOFT DYNAMIC SCANNER ---
set "UBI_GAME_ID="
set "UBI_FRIENDLY_NAME="

echo "!INPUT_GAME!" | findstr /i "blacklist" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Splinter Cell Blacklist"
    set "UBI_GAME_ID=91"
    set "UBI_FRIENDLY_NAME=Tom Clancy's Splinter Cell Blacklist"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wd1" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=WatchDogs 1"
    set "UBI_GAME_ID=541"
    set "UBI_FRIENDLY_NAME=Watch Dogs 1"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wd2" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=WatchDogs 2"
    set "UBI_GAME_ID=3619"
    set "UBI_FRIENDLY_NAME=Watch Dogs 2"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wdl" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=WatchDogs Legion"
    set "UBI_GAME_ID=3353"
    set "UBI_FRIENDLY_NAME=Watch Dogs Legion"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "fc5" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Far Cry 5"
    set "UBI_GAME_ID=4310"
    set "UBI_FRIENDLY_NAME=Far Cry 5"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "fc6" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Far Cry 6"
    set "UBI_GAME_ID=5291"
    set "UBI_FRIENDLY_NAME=Far Cry 6"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "acv" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Valhalla"
    set "UBI_GAME_ID=4256"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Valhalla"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "aco" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Odyssey"
    set "UBI_GAME_ID=5059"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Odyssey"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "ori" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Origins"
    set "UBI_GAME_ID=3539"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Origins"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "div2" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=The Division 2"
    set "UBI_GAME_ID=3539"
    set "UBI_FRIENDLY_NAME=Tom Clancy's The Division 2"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "grw" >nul
if not equal errorlevel 1 (
    set "GAME_NAME=Ghost Recon Wildlands"
    set "UBI_GAME_ID=1771"
    set "UBI_FRIENDLY_NAME=Tom Clancy's Ghost Recon Wildlands"
    goto RUN_UBI_SCAN
)

:: Custom fallback if no keywords matched
set "GAME_NAME=%INPUT_GAME%"
set /p "SAVE_PATH=Enter Live Save Path manually: "
goto FINALIZE_GAME_SETUP

:RUN_UBI_SCAN
set "SAVE_PATH="
call :COLOR_TEXT "[+] Scanning all local drives (A-Z) for Ubisoft savegames..." "YELLOW"

:: 1. Sweep standard Ubisoft Connect installation paths across ALL drives (A-Z)
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\Ubisoft Game Launcher\savegames" (
        for /d %%G in ("%%D:\Ubisoft Game Launcher\savegames\*") do (
            if exist "%%G\%UBI_GAME_ID%" (
                set "SAVE_PATH=%%G\%UBI_GAME_ID%"
                call :COLOR_TEXT "[+] Found standard path on drive %%D: !SAVE_PATH!" "GREEN"
                goto FINALIZE_GAME_SETUP
            )
        )
    )
    
    :: 2. Check for custom backup roots like H:\ubisaves\%UBI_GAME_ID% or H:\ubisaves\savegames\%UBI_GAME_ID%
    if exist "%%D:\ubisaves\%UBI_GAME_ID%" (
        set "SAVE_PATH=%%D:\ubisaves\%UBI_GAME_ID%"
        call :COLOR_TEXT "[+] Found custom path on drive %%D: !SAVE_PATH!" "GREEN"
        goto FINALIZE_GAME_SETUP
    )
    if exist "%%D:\ubisaves\savegames\%UBI_GAME_ID%" (
        set "SAVE_PATH=%%D:\ubisaves\savegames\%UBI_GAME_ID%"
        call :COLOR_TEXT "[+] Found custom path on drive %%D: !SAVE_PATH!" "GREEN"
        goto FINALIZE_GAME_SETUP
    )
)

:: 3. Manual fallback if automated sweeps miss it entirely
call :COLOR_TEXT "[!] Automatic scan missed game ID %UBI_GAME_ID% across all drives." "RED"
set /p "SAVE_PATH=Manually enter save path: "
goto FINALIZE_GAME_SETUP

:: =================================================================
:: FINALIZE GAME SETUP & LAUNCH PROFILE HUB
:: =================================================================
:FINALIZE_GAME_SETUP
if "%WORKSPACE%"=="" set "WORKSPACE=D:\mods\All in 1 game"

cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 WORKSPACE CONFIGURATION" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Current or Default Workspace:
echo   %WORKSPACE%
echo.
set /p "USER_WS=Press Enter to keep this, or type a new path: "

if not "%USER_WS%"=="" set "WORKSPACE=%USER_WS%"

set "ACTIVE_PROFILE=Default"

:: Create game folder and cache its path permanently
if not exist "%WORKSPACE%\%GAME_NAME%" mkdir "%WORKSPACE%\%GAME_NAME%"
echo %SAVE_PATH%> "%WORKSPACE%\%GAME_NAME%\game_path.txt"

call :WRITE_CONFIG
goto ACTION_SWITCH

:SPLASH_SCREEN
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                  SAVE MANAGER - WELCOME BACK" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
call :COLOR_TEXT "   Current Game   : %GAME_NAME%" "GREEN"
call :COLOR_TEXT "   Active Profile : %ACTIVE_PROFILE%" "WHITE"
echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo   [1] Go to Main Menu (Save Inspector)
echo   [2] Switch Game
echo   [3] Create New Entry
echo   [4] Quick Backup (%GAME_NAME% ----^> %ACTIVE_PROFILE% Saves Now)
echo   [5] Cycle Between Profiles
echo   [X] Exit
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
set "splash_choice="
set /p "splash_choice=Select option: "

if "%splash_choice%"=="1" goto ACTION_INSPECTOR
if "%splash_choice%"=="2" goto SWITCH_EXISTING_GAME
if "%splash_choice%"=="3" goto :Supported_games


if "%splash_choice%"=="4" (
    echo.
    call :COLOR_TEXT "[i] Pulling live files into: \"%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%\"" "YELLOW"
    if not exist "%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%" mkdir "%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%"
    robocopy "%SAVE_PATH%" "%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
    call :COLOR_TEXT "[SUCCESS] Quick backup complete." "GREEN"
    pause
    goto SPLASH_SCREEN
)

if /i "%splash_choice%"=="5" goto CYCLE_PROFILE
if /i "%splash_choice%"=="X" exit
goto SPLASH_SCREEN

:: =================================================================
:: IN-PLACE PROFILE CYCLER (Splash Screen Option 4)
:: =================================================================
:CYCLE_PROFILE
set "count=0"
if not exist "%WORKSPACE%\%GAME_NAME%" mkdir "%WORKSPACE%\%GAME_NAME%"

:: Build the array of existing profiles
for /d %%D in ("%WORKSPACE%\%GAME_NAME%\*") do (
    set /a count+=1
    set "prof[!count!]=%%~nD"
)

:: If no profiles exist yet, default to a safe name
if %count%==0 (
    set "ACTIVE_PROFILE=Default"
    goto SAVE_CYCLE_CONFIG
)

:: Find where we currently are in the list and grab the next one
set "matched=0"
for /l %%i in (1,1,%count%) do (
    if /i "!prof[%%i]!"=="%ACTIVE_PROFILE%" (
        set /a "next_i=%%i+1"
        set "matched=1"
    )
)

:: If current profile isn't in the folder list or we hit the end, loop back to #1
if %matched%==0 set "next_i=1"
if !next_i! gtr %count% set "next_i=1"

:: Set the new active profile
set "ACTIVE_PROFILE=!prof[%next_i%]!"

:SAVE_CYCLE_CONFIG
:: Re-save the updated configuration to disk silently so it persists
(
    echo GAME_NAME=%GAME_NAME%
    echo SAVE_PATH=%SAVE_PATH%
    echo WORKSPACE=%WORKSPACE%
    echo ACTIVE_PROFILE=%ACTIVE_PROFILE%
    echo PROFILE_COLOR=%PROFILE_COLOR%
) > "%CONFIG_FILE%"

:: Jump straight back to the splash screen without leaving the page
goto SPLASH_SCREEN

:: =================================================================
:: LIVE GAME SAVE INSPECTOR & HUB
:: =================================================================
:ACTION_INSPECTOR
set "TARGET_PROFILE_DIR=%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%"

cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "         SAVE INSPECTOR: [%GAME_NAME%]" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo    Active Profile: %ACTIVE_PROFILE%
echo    Live Save Path: %SAVE_PATH%
echo    TARGET_PROFILE: %WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
call :COLOR_TEXT "    Live Save Files (Sorted by Write Date):" "WHITE"
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"

if exist "%SAVE_PATH%" (
    :: Prints the header info of the dir command with a custom sub-second delay
    for /f "delims=" %%a in ('dir "%SAVE_PATH%" /T:W /O:D ^| findstr /r "^[0-9]"') do (
        echo   %%a
        :: Custom delay: Adjust the -w milliseconds value (e.g., 50, 100, or 200) to change speed
        ping 127.0.0.1 -n 1 -w 5 >nul 2>&1
    )
) else (
    call :COLOR_TEXT "[!] Warning: Live save path is currently inaccessible." "RED"
)

call :COLOR_TEXT "=================================================================" "THEME"
echo    [1] Backup %GAME_NAME%s Save ---^> %ACTIVE_PROFILE%)
echo    [2] Restore %ACTIVE_PROFILE% ---^> %GAME_NAME%s Save)
echo    [3] Switch / Create Profile
echo    [4] Change Theme Color
echo    [5] Change Game / Re-setup
echo    [6] Cloud Sync / Import (Google Drive / OneDrive / Dropbox)
echo    [7] Reset Game Config
echo    [X] Exit
call :COLOR_TEXT "=================================================================" "THEME"
set "insp_choice="
set /p "insp_choice=Selection: "

if "%insp_choice%"=="1" (
    echo.
    call :COLOR_TEXT "[i] Pulling live files into: \"%TARGET_PROFILE_DIR%\"" "YELLOW"
    if not exist "%TARGET_PROFILE_DIR%" mkdir "%TARGET_PROFILE_DIR%"
    robocopy "%SAVE_PATH%" "%TARGET_PROFILE_DIR%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
    call :COLOR_TEXT "[SUCCESS] Backup complete." "GREEN"
    pause
    goto ACTION_INSPECTOR
)

if "%insp_choice%"=="2" (
    echo.
    call :COLOR_TEXT "⚠️ WARNING: This will OVERWRITE live game saves with [%ACTIVE_PROFILE%]!" "RED"
    set /p "conf=Confirm Sync? (Y/N): "
    if /i "!conf!"=="Y" (
        if not exist "%SAVE_PATH%" mkdir "%SAVE_PATH%"
        robocopy "%TARGET_PROFILE_DIR%" "%SAVE_PATH%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
        call :COLOR_TEXT "[SUCCESS] Live game folder updated." "GREEN"
    )
    pause
    goto ACTION_INSPECTOR
)

if "%insp_choice%"=="3" goto ACTION_SWITCH
if "%insp_choice%"=="4" goto CHANGE_THEME
if "%insp_choice%"=="5" goto CHANGE_GAME
if "%insp_choice%"=="6" goto CloudInterface
if "%insp_choice%"=="7" (
    del /q "%CONFIG_FILE%"
    call :COLOR_TEXT "[INFO] Config reset. Restart script." "YELLOW"
    pause
    goto :eof
)
if /i "%insp_choice%"=="X" exit
goto ACTION_INSPECTOR

:: =================================================================
:: PROFILE SWITCHER & CREATOR
:: =================================================================
:ACTION_SWITCH
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                PROFILES FOR: %GAME_NAME%" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Existing profile folders:
echo.

set "count=0"
if not exist "%WORKSPACE%\%GAME_NAME%" mkdir "%WORKSPACE%\%GAME_NAME%"

for /d %%D in ("%WORKSPACE%\%GAME_NAME%\*") do (
    set /a count+=1
    set "prof[!count!]=%%~nD"
    echo    [!count!] %%~nD
)

echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo Type an existing profile number to switch, OR type a brand 
echo new profile name to create it instantly.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
set "p_choice="
set /p "p_choice=Select number or type new name: "

if defined prof[%p_choice%] (
    set "ACTIVE_PROFILE=!prof[%p_choice%]!"
) else (
    set "ACTIVE_PROFILE=%p_choice%"
)

call :WRITE_CONFIG

echo.
call :COLOR_TEXT "[+] Active profile switched to: !ACTIVE_PROFILE!" "GREEN"
pause
goto ACTION_INSPECTOR

:: =================================================================
:: THEME COLOR SELECTION SUBROUTINE
:: =================================================================
:CHANGE_THEME
cls
echo ==================================================
call :COLOR_TEXT "              THEME COLOR SELECTION" "THEME"
echo.
echo ==================================================
call :COLOR_TEXT " 1. Green    " "92"
call :COLOR_TEXT " 2. Red      " "91"
call :COLOR_TEXT " 3. White    " "97"
call :COLOR_TEXT " 4. Yellow   " "93"
echo.
call :COLOR_TEXT " 5. Cyan     " "96"
call :COLOR_TEXT " 6. Blue     " "94"
call :COLOR_TEXT " 7. Magenta  " "95"
call :COLOR_TEXT " 8. Gray     " "90"
echo.
echo B. Back to Main Hub
echo ==================================================
set /p "theme_choice=Select: "

if "%theme_choice%"=="1" set "PROFILE_COLOR=92"
if "%theme_choice%"=="2" set "PROFILE_COLOR=91"
if "%theme_choice%"=="3" set "PROFILE_COLOR=97"
if "%theme_choice%"=="4" set "PROFILE_COLOR=93"
if "%theme_choice%"=="5" set "PROFILE_COLOR=96"
if "%theme_choice%"=="6" set "PROFILE_COLOR=94"
if "%theme_choice%"=="7" set "PROFILE_COLOR=95"
if "%theme_choice%"=="8" set "PROFILE_COLOR=90"

if /i "%theme_choice%"=="B" goto ACTION_INSPECTOR

call :WRITE_CONFIG
echo.
call :COLOR_TEXT "[+] Theme updated and config saved!" "GREEN"
timeout /t 2 >nul
goto CHANGE_THEME

:: =================================================================
:: CHANGE GAME / RE-SETUP SUBROUTINE
:: =================================================================
:CHANGE_GAME
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 SWITCH ACTIVE GAME" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Would you like to select a new game or switch games^?
echo [1] Yes, change game (Switch existing)
echo [2] Create a new game
echo [m] List All Supported Games ^& Keywords
echo [B] Back to Inspector
echo.
set "cg_choice="
set /p "cg_choice=Selection (1/2/B): "

if "%cg_choice%"=="1" goto SWITCH_EXISTING_GAME
if "%cg_choice%"=="2" goto CREATE_NEW_GAME
if "%cg_choice%"=="m" goto Supported_games
if "%cg_choice%"=="b" goto ACTION_INSPECTOR
goto CHANGE_GAME

:: =================================================================
:: SWITCH TO EXISTING GAME FOLDER SUBROUTINE
:: =================================================================
:SWITCH_EXISTING_GAME
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               EXISTING GAMES IN WORKSPACE" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Workspace: %WORKSPACE%
echo.

set "g_count=0"
if not exist "%WORKSPACE%" mkdir "%WORKSPACE%"

for /d %%G in ("%WORKSPACE%\*") do (
    set /a g_count+=1
    set "game_opt[!g_count!]=%%~nG"
    
    set "SAVED_GAME_PATH="
    if exist "%WORKSPACE%\%%~nG\game_path.txt" (
        set /p SAVED_GAME_PATH=<"%WORKSPACE%\%%~nG\game_path.txt"
        echo    [!g_count!] %%~nG  [Path: !SAVED_GAME_PATH!]
    ) else (
        echo    [!g_count!] %%~nG  [Path: Not Configured]
    )
)

if %g_count% equ 0 (
    call :COLOR_TEXT "[!] No existing game folders found in workspace." "YELLOW"
    pause
    goto CHANGE_GAME
)

echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
set "g_choice="
set /p "g_choice=Select game number (or press Enter to go back): "

if not defined g_choice goto CHANGE_GAME
if defined game_opt[%g_choice%] (
    set "GAME_NAME=!game_opt[%g_choice%]!"
    
    set "SAVE_PATH="
    if exist "%WORKSPACE%\!GAME_NAME!\game_path.txt" (
        set /p SAVE_PATH=<"%WORKSPACE%\!GAME_NAME!\game_path.txt"
    )
    
    :: If no path file exists, attempt auto-detection first!
    if "!SAVE_PATH!"=="" (
        echo.
        call :COLOR_TEXT "[i] Selected Game: !GAME_NAME!" "YELLOW"
        call :COLOR_TEXT "[i] Attempting auto-detection..." "CYAN"
        
        call :AUTO_DETECT_PATH
        
        :: If auto-detection still couldn't find it, fallback to manual prompt
        if "!SAVE_PATH!"=="" (
            call :COLOR_TEXT "[!] Automatic detection failed. Please enter path manually:" "RED"
            set /p "SAVE_PATH=Live Save Path: "
        )
        
        :: Save the discovered/entered path for future switches
        if not exist "%WORKSPACE%\!GAME_NAME!" mkdir "%WORKSPACE%\!GAME_NAME!"
        echo !SAVE_PATH!> "%WORKSPACE%\!GAME_NAME!\game_path.txt"
    ) else (
        echo.
        call :COLOR_TEXT "[+] Loaded saved path for !GAME_NAME!" "GREEN"
    
    
    set "ACTIVE_PROFILE=Default"
    call :WRITE_CONFIG
    
    echo.
    call :COLOR_TEXT "[+] Successfully switched to !GAME_NAME!" "GREEN"
    timeout /t 2 >nul
    goto ACTION_SWITCH
)

goto SWITCH_EXISTING_GAME

:: =================================================================
:: CREATE NEW GAME SUBROUTINE (Bypasses workspace prompt)
:: =================================================================
:CREATE_NEW_GAME
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 CREATE NEW GAME PROFILE" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Current Workspace: %WORKSPACE%
echo.
set "INPUT_GAME="
set /p "INPUT_GAME=Enter New Game Name / Keyword: (e.g., skyrimse, fo4, ats, ts4, hzd, blacklist, wd2, fc5, etc.) or type a custom name: "

if "%INPUT_GAME%"=="" goto CHANGE_GAME

:: Dual-Doc & Custom Games Check
echo "!INPUT_GAME!" | findstr /i "skyrimse" >nul
if not errorlevel 1 (
    set "GAME_NAME=Skyrim Special Edition"
    if exist "%USERPROFILE%\OneDrive\Documents\My Games\Skyrim Special Edition" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Skyrim Special Edition"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Skyrim Special Edition"
    )
    call :COLOR_TEXT "[+] Keyword matched: Skyrim SE" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "fo4" >nul
if not errorlevel 1 (
    set "GAME_NAME=Fallout 4"
    if exist "%USERPROFILE%\OneDrive\Documents\My Games\Fallout4" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Fallout4"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Fallout4"
    )
    call :COLOR_TEXT "[+] Keyword matched: Fallout 4" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "ats" >nul
if not errorlevel 1 (
    set "GAME_NAME=American Truck Simulator"
    if exist "%USERPROFILE%\OneDrive\Documents\American Truck Simulator" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\American Truck Simulator"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\American Truck Simulator"
    )
    call :COLOR_TEXT "[+] Keyword matched: American Truck Simulator" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "ts4" >nul
if not errorlevel 1 (
    set "GAME_NAME=The Sims 4"
    if exist "%USERPROFILE%\OneDrive\Documents\Electronic Arts\The Sims 4" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Electronic Arts\The Sims 4"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Electronic Arts\The Sims 4"
    )
    call :COLOR_TEXT "[+] Keyword matched: The Sims 4" "GREEN"
    goto FINALIZE_GAME_SETUP
)

echo "!INPUT_GAME!" | findstr /i "ets2" >nul
if not errorlevel 1 (
    set "GAME_NAME=Euro Truck Simulator 2"
    if exist "%USERPROFILE%\OneDrive\Documents\Euro Truck Simulator 2" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Euro Truck Simulator 2"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Euro Truck Simulator 2"
    )
    call :COLOR_TEXT "[+] Keyword matched: Euro Truck Simulator 2" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "hitmanbm" >nul
if not errorlevel 1 (
    set "GAME_NAME=Hitman Blood Money"
    if exist "%USERPROFILE%\OneDrive\Documents\Hitman Blood Money" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Hitman Blood Money"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Hitman Blood Money"
    )
    call :COLOR_TEXT "[+] Keyword matched: Hitman Blood Money" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "hwl" >nul
if not errorlevel 1 (
    set "GAME_NAME=Hogwarts Legacy"
    if exist "%USERPROFILE%\OneDrive\Documents\Hogwarts Legacy" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Hogwarts Legacy"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Hogwarts Legacy"
    )
    call :COLOR_TEXT "[+] Keyword matched: Hogwarts Legacy" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "hzd" >nul
if not errorlevel 1 (
    set "GAME_NAME=Horizon Zero Dawn"
    if exist "%USERPROFILE%\OneDrive\Documents\Horizon Zero Dawn" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Horizon Zero Dawn"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Horizon Zero Dawn"
    )
    call :COLOR_TEXT "[+] Keyword matched: Horizon Zero Dawn" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "avengers" >nul
if not errorlevel 1 (
    set "GAME_NAME=Marvels Avengers"
    if exist "%USERPROFILE%\OneDrive\Documents\Marvel's Avengers" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Marvel's Avengers"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Marvel's Avengers"
    )
    call :COLOR_TEXT "[+] Keyword matched: Marvel's Avengers" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "smr" >nul
if not errorlevel 1 (
    set "GAME_NAME=Spider Man Remastered"
    if exist "%USERPROFILE%\OneDrive\Documents\Marvel's Spider-Man Remastered" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Marvel's Spider-Man Remastered"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Marvel's Spider-Man Remastered"
    )
    call :COLOR_TEXT "[+] Keyword matched: Spider-Man Remastered" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "rdr2" >nul
if not errorlevel 1 (
    set "GAME_NAME=Red Dead Redemption 2"
    if exist "%USERPROFILE%\OneDrive\Documents\Rockstar Games\Red Dead Redemption 2" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Rockstar Games\Red Dead Redemption 2"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Rockstar Games\Red Dead Redemption 2"
    )
    call :COLOR_TEXT "[+] Keyword matched: Red Dead Redemption 2" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "tw3" >nul
if not errorlevel 1 (
    set "GAME_NAME=The Witcher 3"
    if exist "%USERPROFILE%\OneDrive\Documents\The Witcher 3" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\The Witcher 3"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\The Witcher 3"
    )
    call :COLOR_TEXT "[+] Keyword matched: The Witcher 3" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "bak" >nul
if not errorlevel 1 (
    set "GAME_NAME=Batman Arkham Knight"
    if exist "%USERPROFILE%\OneDrive\Documents\WB Games" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\WB Games"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\WB Games"
    )
    call :COLOR_TEXT "[+] Keyword matched: Batman Arkham Knight" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "hunter" >nul
if not errorlevel 1 (
    set "GAME_NAME=The Hunter Call Of The Wild"
    if exist "%USERPROFILE%\OneDrive\Documents\Avalanche Studios" (
        set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Avalanche Studios"
    ) else (
        set "SAVE_PATH=%USERPROFILE%\Documents\Avalanche Studios"
    )
    call :COLOR_TEXT "[+] Keyword matched: The Hunter: Call of the Wild" "GREEN"
    goto FINISH_NEW_GAME
)

echo "!INPUT_GAME!" | findstr /i "scct" >nul
if not errorlevel 1 (
    set "GAME_NAME=Splinter Cell Chaos Theory"
    if exist "%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory" (
        set "SAVE_PATH=%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
    ) else (
        set "SAVE_PATH=C:\ProgramData\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
    )
    call :COLOR_TEXT "[+] Keyword matched: Splinter Cell Chaos Theory" "GREEN"
    goto FINISH_NEW_GAME
)

:: Ubisoft Dynamic Checks for Creator Menu
echo "!INPUT_GAME!" | findstr /i "blacklist" >nul
if not errorlevel 1 (
    set "GAME_NAME=Splinter Cell Blacklist"
    set "UBI_GAME_ID=91"
    set "UBI_FRIENDLY_NAME=Tom Clancy's Splinter Cell Blacklist"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wd1" >nul
if not errorlevel 1 (
    set "GAME_NAME=Watch Dogs 1"
    set "UBI_GAME_ID=541"
    set "UBI_FRIENDLY_NAME=Watch Dogs 1"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wd2" >nul
if not errorlevel 1 (
    set "GAME_NAME=WatchDogs 2"
    set "UBI_GAME_ID=3619"
    set "UBI_FRIENDLY_NAME=Watch Dogs 2"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wdl" >nul
if not errorlevel 1 (
    set "GAME_NAME=WatchDogs Legion"
    set "UBI_GAME_ID=3353"
    set "UBI_FRIENDLY_NAME=Watch Dogs Legion"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "fc5" >nul
if not errorlevel 1 (
    set "GAME_NAME=Far Cry 5"
    set "UBI_GAME_ID=4310"
    set "UBI_FRIENDLY_NAME=Far Cry 5"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "fc6" >nul
if not errorlevel 1 (
    set "GAME_NAME=Far Cry 6"
    set "UBI_GAME_ID=5291"
    set "UBI_FRIENDLY_NAME=Far Cry 6"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "acv" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassins Creed Valhalla"
    set "UBI_GAME_ID=4256"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Valhalla"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "aco" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassins Creed Odyssey"
    set "UBI_GAME_ID=5059"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Odyssey"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "ori" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassins Creed Origins"
    set "UBI_GAME_ID=3539"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Origins"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "div2" >nul
if not errorlevel 1 (
    set "GAME_NAME=The Division 2"
    set "UBI_GAME_ID=3539"
    set "UBI_FRIENDLY_NAME=Tom Clancy's The Division 2"
    goto RUN_NEW_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "grw" >nul
if not errorlevel 1 (
    set "GAME_NAME=Ghost Recon Wildlands"
    set "UBI_GAME_ID=1771"
    set "UBI_FRIENDLY_NAME=Tom Clancy's Ghost Recon Wildlands"
    goto RUN_NEW_UBI_SCAN
)

set "GAME_NAME=%INPUT_GAME%"
set /p "SAVE_PATH=Enter Live Save Path manually: "
goto FINISH_NEW_GAME

:SUPPORTED_GAMES
mode con: cols=85 lines=65
cls

call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 COMPLETE LIST OF SUPPORTED AUTO-SCAN GAMES" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"

for %%L in (
    "[DOCUMENTS / DUAL-PATH GAMES]"
    "   01. Skyrim Special Edition ............ [skyrimse]"
    "   02. Fallout 4 ......................... [fo4]"
    "   03. American Truck Simulator .......... [ats]"
    "   04. The Sims 4 ........................ [ts4]"
    "   05. Euro Truck Simulator 2 ............ [ets2]"
    "   06. Hitman Blood Money ................ [hitmanbm]"
    "   07. Hogwarts Legacy (mods) ............ [hwl]"
    "   08. Horizon Zero Dawn ................. [hzd]"
    "   09. The Hunter (Call of the Wild) ..... [hunter]"
    "   10. inZOI ............................. [inzoi]"
    "   11. Marvel's Avengers ................. [avengers]"
    "   12. Marvel's Spider-Man Remastered .... [smr]"
    "   13. A Way Out ......................... [awayout]"
    "   14. Fallout: New Vegas ................ [fonv]"
    "   15. Far Cry New Dawn .................. [fcnd]"
    "   16. Life Is Strange 1 ................. [lis1]"
    "   17. Life Is Strange 3 ................. [lis3]"
    "   18. Life Is Strange: Double Exposure .. [lisde]"
    "   19. Beyond: Two Souls ................. [bts]"
    "   20. Red Dead Redemption 2 ............. [rdr2]"
    "   21. The Walking Dead .................. [twd]"
    "   22. The Witcher 3 ..................... [tw3]"
    "   23. Tomb Raider (2013) ................ [tr13]"
    "   24. Batman Arkham Knight .............. [bak]"
    "[UBISOFT GAMES]"
    "   25. Splinter Cell Blacklist ........... [blacklist]"
    "   26. Watch Dogs 1 ...................... [wd1]"
    "   27. Watch Dogs 2 ...................... [wd2]"
    "   28. Watch Dogs Legion ................. [wdl]"
    "   29. Far Cry 5 ......................... [fc5]"
    "   30. Far Cry 6 ......................... [fc6]"
    "   31. Assassin's Creed Valhalla ......... [acv]"
    "   32. Assassin's Creed Odyssey .......... [aco]"
    "   33. Assassin's Creed Origins .......... [ori]"
    "   34. Tom Clancy's The Division 2 ....... [div2]"
    "   35. Tom Clancy's Ghost Recon Wildlands..[grw]"
    "[MANUAL / OTHER]"
    "   36. Splinter Cell: Chaos Theory ....... [scct]"
    "   37. (Any custom name for manual path input)"
) do (
    echo %%~L
    ping 127.0.0.1 -n 1 -w 5 >nul 2>&1
)

echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo  [TIP] Know your game? Just type its keyword (e.g., fo4, ets2, scct) 
echo        at the new game prompt screen to map it instantly.
echo.
echo        Don't see your game? No problem! This script is completely 
echo        universal—you can type any custom game name and provide 
echo        its save path manually.
call :COLOR_TEXT "=================================================================" "THEME"
echo.
set /p "MENU_CHOICE=Press Enter to create a new game profile, or type 'M' to return to menu: "
if /i "%MENU_CHOICE%"=="m" goto CHANGE_GAME
goto CREATE_NEW_GAME

:RUN_NEW_UBI_SCAN
set "SAVE_PATH="
call :COLOR_TEXT "[+] Scanning all local drives (A-Z) for Ubisoft savegames..." "YELLOW"

:: 1. Sweep standard Ubisoft Connect installation paths across ALL drives (A-Z)
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\Ubisoft Game Launcher\savegames" (
        for /d %%G in ("%%D:\Ubisoft Game Launcher\savegames\*") do (
            if exist "%%G\%UBI_GAME_ID%" (
                set "SAVE_PATH=%%G\%UBI_GAME_ID%"
                call :COLOR_TEXT "[+] Found standard path on drive %%D: !SAVE_PATH!" "GREEN"
                goto FINALIZE_GAME_SETUP
            )
        )
    )
    
    :: 2. Check for custom backup roots like H:\ubisaves\%UBI_GAME_ID% or H:\ubisaves\savegames\%UBI_GAME_ID%
    if exist "%%D:\ubisaves\%UBI_GAME_ID%" (
        set "SAVE_PATH=%%D:\ubisaves\%UBI_GAME_ID%"
        call :COLOR_TEXT "[+] Found custom path on drive %%D: !SAVE_PATH!" "GREEN"
        goto FINALIZE_GAME_SETUP
    )
    if exist "%%D:\ubisaves\savegames\%UBI_GAME_ID%" (
        set "SAVE_PATH=%%D:\ubisaves\savegames\%UBI_GAME_ID%"
        call :COLOR_TEXT "[+] Found custom path on drive %%D: !SAVE_PATH!" "GREEN"
        goto FINALIZE_GAME_SETUP
    )
)

:: 3. Manual fallback if automated sweeps miss it entirely
call :COLOR_TEXT "[!] Automatic scan missed game ID %UBI_GAME_ID% across all drives." "RED"
set /p "SAVE_PATH=Manually enter save path: "
goto FINISH_NEW_GAME

:FINISH_NEW_GAME
set "ACTIVE_PROFILE=Default"
call :WRITE_CONFIG
echo.
call :COLOR_TEXT "[+] New game workspace created successfully!" "GREEN"
pause
goto ACTION_SWITCH

:: =================================================================
:: SHARED AUTO-DETECTION SUBROUTINE (Keywords & Ubisoft Scanner)
:: =================================================================
:AUTO_DETECT_PATH
set "SAVE_PATH="

:: 1. Check keywords based on the game name folder
echo "!GAME_NAME!" | findstr /i "hunter" >nul
if not errorlevel 1 (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\Avalanche Studios"
    call :COLOR_TEXT "[+] Auto-matched: The Hunter: Call of the Wild" "GREEN"
    goto :eof
)

echo "!GAME_NAME!" | findstr /i "chaos" >nul
if not errorlevel 1 (
    set "SAVE_PATH=%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
    call :COLOR_TEXT "[+] Auto-matched: Splinter Cell Chaos Theory" "GREEN"
    goto :eof
)

:: 2. Check Ubisoft game IDs
set "UBI_GAME_ID="
echo "!GAME_NAME!" | findstr /i "blacklist" >nul
if not errorlevel 1 set "UBI_GAME_ID=91"

echo "!GAME_NAME!" | findstr /i "watchdogs2 wd2" >nul
if not errorlevel 1 set "UBI_GAME_ID=3619"

if defined UBI_GAME_ID (
    call :COLOR_TEXT "[+] Scanning all local drives (A-Z) for Ubisoft savegames (ID: %UBI_GAME_ID%)..." "YELLOW"
    for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%D:\Ubisoft Game Launcher\savegames" (
            for /d %%G in ("%%D:\Ubisoft Game Launcher\savegames\*") do (
                if exist "%%G\%UBI_GAME_ID%" (
                    set "SAVE_PATH=%%G\%UBI_GAME_ID%"
                    call :COLOR_TEXT "[+] Found standard path on drive %%D: !SAVE_PATH!" "GREEN"
                    goto :eof
                )
            )
        )
        if exist "%%D:\ubisaves\%UBI_GAME_ID%" (
            set "SAVE_PATH=%%D:\ubisaves\%UBI_GAME_ID%"
            call :COLOR_TEXT "[+] Found custom path on drive %%D: !SAVE_PATH!" "GREEN"
            goto :eof
        )
        if exist "%%D:\ubisaves\savegames\%UBI_GAME_ID%" (
            set "SAVE_PATH=%%D:\ubisaves\savegames\%UBI_GAME_ID%"
            call :COLOR_TEXT "[+] Found custom path on drive %%D: !SAVE_PATH!" "GREEN"
            goto :eof
        )
    )
    call :COLOR_TEXT "[!] Automatic scan missed game ID %UBI_GAME_ID%." "RED"
)
goto :eof

:: =================================================================
:: CLOUD INTERFACE SUBMENU
:: =================================================================
:CloudInterface
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               CLOUD SYNC & LINKS MANAGER" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo      [1] Download Links / Quick Shortcuts
echo      [2] Import/Export Saves (Drive / Dropbox)
echo      [3] Back to Main Inspector
echo.
set "cloud_choice="
set /p "cloud_choice=Select option: "

if "%cloud_choice%"=="1" goto ADD_CLOUD_LINK
if "%cloud_choice%"=="2" goto Cloud
if "%cloud_choice%"=="3" goto ACTION_INSPECTOR
goto CloudInterface

:: =================================================================
:: CREATE CLOUD LINK DIRECTORY SHORTCUT
:: =================================================================
:ADD_CLOUD_LINK
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               GET CLOUD DESKTOP CLIENTS" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo This will open your web browser to download the official
echo desktop apps so they integrate directly into Windows file pickers.
echo.
echo   [1] Download Dropbox Desktop App
echo   [2] Download Google Drive for Desktop
echo   [3] Download OneDrive for Desktop (Built-in to W10/W11, reinstall if missing)
echo   [4] Back to Cloud Menu
echo.
set "app_choice="
set /p "app_choice=Select option: "

if "%app_choice%"=="1" (
    start "" "https://www.dropbox.com/download"
    goto GET_DESKTOP_APPS
)
if "%app_choice%"=="2" (
    start "" "https://www.google.com/drive/download/"
    goto GET_DESKTOP_APPS
)
if "%app_choice%"=="3" (
    start "" "https://www.microsoft.com/en-us/microsoft-365/onedrive/download"
    goto GET_DESKTOP_APPS
)
if "%app_choice%"=="4" goto CloudInterface

goto GET_DESKTOP_APPS

:: =================================================================
:: CLOUD SAVE IMPORT WORKFLOW
:: =================================================================
:Cloud
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "             CLOUD SAVE IMPORT (DRIVE / DROPBOX)" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Select the cloud folder containing your save files for: %GAME_NAME%
echo.
pause

:: Call the separate PowerShell browser subroutine
call :SELECT_CLOUD_FOLDER

if "%SELECTED_CLOUD_DIR%"=="" (
    call :COLOR_TEXT "[!] No folder selected. Returning..." "YELLOW"
    timeout /t 2 >nul
    goto CloudInterface
)

call :COLOR_TEXT "[+] Selected: %SELECTED_CLOUD_DIR%" "CYAN"
echo.
call :COLOR_TEXT "Where would you like to import these saves?" "WHITE"
echo   [1] Import to Active Profile Folder (%ACTIVE_PROFILE%)
echo   [2] Import to Main Game Root Folder (%GAME_NAME%)
echo.
set "import_dest="
set /p "import_dest=Select destination (1 or 2): "

if "%import_dest%"=="2" (
    set "TARGET_DIR=%WORKSPACE%\%GAME_NAME%"
) else (
    set "TARGET_DIR=%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%"
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo.
call :COLOR_TEXT "[+] Target Directory: %TARGET_DIR%" "YELLOW"
set /p "CONFIRM=Import and overwrite saves in this directory? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto CloudInterface

call :COLOR_TEXT "[+] Copying files from cloud folder..." "YELLOW"
robocopy "%SELECTED_CLOUD_DIR%" "%TARGET_DIR%" /e /xo >nul

call :COLOR_TEXT "[+] Successfully imported saves from cloud storage!" "GREEN"
timeout /t 2 >nul
goto ACTION_INSPECTOR


:: =================================================================
:: POWERSHELL FOLDER BROWSER DIALOG SUBROUTINE
:: =================================================================
:SELECT_CLOUD_FOLDER
set "SELECTED_CLOUD_DIR="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Select Cloud Save Folder (Dropbox / Drive / OneDrive)'; if ($f.ShowDialog() -eq 'OK') { $f.SelectedPath }"`) do (
    set "SELECTED_CLOUD_DIR=%%I"
)
goto :eof

:: =================================================================
:: WRITE CONFIG HELPER SUBROUTINE
:: =================================================================
:WRITE_CONFIG
(
    echo GAME_NAME=%GAME_NAME%
    echo SAVE_PATH=%SAVE_PATH%
    echo WORKSPACE=%WORKSPACE%
    echo ACTIVE_PROFILE=%ACTIVE_PROFILE%
    echo PROFILE_COLOR=%PROFILE_COLOR%
) > "%CONFIG_FILE%" 2>nul
goto :eof

:: =================================================================
:: GLOBAL: COLOR_TEXT SUBROUTINE
:: =================================================================
:COLOR_TEXT
set "TXT=%~1"
set "VAL=%~2"
set "C=97"

if "%VAL%"=="%PROFILE_COLOR%" set "C=%PROFILE_COLOR%" & goto :PRINT
if /i "%VAL%"=="THEME"        set "C=%PROFILE_COLOR%" & goto :PRINT

if /i "%VAL%"=="RED"     set "C=91" & goto :PRINT
if /i "%VAL%"=="GREEN"   set "C=92" & goto :PRINT
if /i "%VAL%"=="YELLOW"  set "C=93" & goto :PRINT
if /i "%VAL%"=="BLUE"    set "C=94" & goto :PRINT
if /i "%VAL%"=="MAGENTA" set "C=95" & goto :PRINT
if /i "%VAL%"=="CYAN"    set "C=96" & goto :PRINT
if /i "%VAL%"=="WHITE"   set "C=97" & goto :PRINT
if /i "%VAL%"=="GRAY"    set "C=90" & goto :PRINT
if "%VAL%" GEQ "90" if "%VAL%" LEQ "97" set "C=%VAL%" & goto :PRINT

:PRINT
<nul set /p "=[%C%m%TXT%[0m"
echo.
goto :eof