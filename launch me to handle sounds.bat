#!/bin/bash
@echo off

set true=1==1
set false=1==0
SET SOUNDS_LIST_FILE=sounds_list.lua
SET CFG_FILE=sounds_list.cfg

cls
set /p mod_name=Insert your mod name: 
echo[
echo you're in %CD%
echo[
set /p folder_path=Complete path to this folder: %mod_name%/
choice /C YN /M "Press Y to add sounds in this folder to programmable speakers (in Factorio), N to cancel the operation."
set state=%ERRORLEVEL%
IF %state% EQU 1 set /p sound_group_name=Insert group name of sounds: 
IF %state% EQU 1 (
	IF [%sound_group_name%]==[] set /p sound_group_name=%mod_name%
)
IF EXIST %SOUNDS_LIST_FILE% del %SOUNDS_LIST_FILE% /f /q
IF EXIST %CFG_FILE% del %CFG_FILE% /f /q

IF %state% EQU 1 echo ### Please, do not change this file manually! >> %CFG_FILE%
IF %state% EQU 1 echo [programmable-speaker-instument] >> %CFG_FILE%
IF %state% EQU 1 echo %sound_group_name%=%sound_group_name% >> %CFG_FILE%
IF %state% EQU 1 echo[ >> %CFG_FILE%
IF %state% EQU 1 echo [programmable-speaker-note] >> %CFG_FILE%

echo -- Please, do not change this file if you're not sure, except sounds_list.name and path! >> %SOUNDS_LIST_FILE%
echo -- You need require this file to your control.lua and add https://mods.factorio.com/mod/zk-lib in your dependencies >> %SOUNDS_LIST_FILE%
echo[ >> %SOUNDS_LIST_FILE%
echo local sounds_list = { >> %SOUNDS_LIST_FILE%
IF %state% EQU 1 echo 	name = %sound_group_name%, --change me, if you want to add these sounds to programmable speakers >> %SOUNDS_LIST_FILE%
IF %state% EQU 2 echo 	name = nil --change me, if you want to add these sounds to programmable speakers >> %SOUNDS_LIST_FILE%
echo 	path = "__%mod_name%__/%folder_path%/", -- path to this folder >> %SOUNDS_LIST_FILE%
echo 	sounds = { >> %SOUNDS_LIST_FILE%
for %%i in (*.ogg) do (
	echo 		{ >> %SOUNDS_LIST_FILE%
	echo 			name = "%%~ni", >> %SOUNDS_LIST_FILE%
	echo 		}, >> %SOUNDS_LIST_FILE%
	IF %state% EQU 1 echo %%~ni=%%~ni >> %CFG_FILE%
)
echo 	} >> %SOUNDS_LIST_FILE%
echo } >> %SOUNDS_LIST_FILE%
echo[ >> %SOUNDS_LIST_FILE%
echo if puan_api then puan_api.add_sounds(sounds_list) end >> %SOUNDS_LIST_FILE%
echo[ >> %SOUNDS_LIST_FILE%
echo return sounds_list >> %SOUNDS_LIST_FILE%
echo[
cls
echo You're almost ready!
echo[
echo # You need to write 'require("__%mod_name%__/%folder_path%/%SOUNDS_LIST_FILE%")' in your %mod_name%/control.lua
echo # Add string "zk-lib" in dependencies of %mod_name%/info.json, example: '"dependencies": ["zk-lib"]'
IF %state% EQU 1 echo # Put sounds_list.cfg in folder %mod_name%/locale/en (it'll provide readable text in the game)
echo[
echo If you found a bug or you have a problem with script etc, please, let us know
echo https://github.com/ZwerOxotnik/Mod-generator
echo This script created by ZwerOxotnik. You can support me on Patreon 'ZwerOxotnik' and on Reddit /r/ZwerOxotnik
echo[
timeout /t -1
