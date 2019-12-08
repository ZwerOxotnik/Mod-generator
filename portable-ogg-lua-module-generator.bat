#!/bin/bash
ECHO OFF

set true=1==1
set false=1==0
SET SOUNDS_LIST_FILE=sounds_list.lua
SET CFG_FILE=sounds_list.cfg

IF EXIST %SOUNDS_LIST_FILE% del %SOUNDS_LIST_FILE% /f /q
IF EXIST %CFG_FILE% del %CFG_FILE% /f /q

echo ### Please, do not change this file! More info: https://www.reddit.com/r/ZwerOxotnik/comments/dv7tpx/you_want_your_own_mod_stay_tuned/ >> %CFG_FILE%
echo [programmable-speaker-note] >> %CFG_FILE%

echo -- Please, do not change this file! More info: https://www.reddit.com/r/ZwerOxotnik/comments/dv7tpx/you_want_your_own_mod_stay_tuned/ >> %SOUNDS_LIST_FILE%
echo return { >> %SOUNDS_LIST_FILE%
echo 	sounds = { >> %SOUNDS_LIST_FILE%
for %%i in (*.ogg) do (
	echo 		{ >> %SOUNDS_LIST_FILE%
	echo 			name = "%%~ni", >> %SOUNDS_LIST_FILE%
	echo 		}, >> %SOUNDS_LIST_FILE%
	echo %%~ni=%%~ni >> %CFG_FILE%
)
echo 	} >> %SOUNDS_LIST_FILE%
echo }, >> %SOUNDS_LIST_FILE%
