#!/usr/bin/env bash
### Generates lua and cfg files to handle .ogg sounds for Factorio
### Source: https://github.com/ZwerOxotnik/Mod-generator


bold=$(tput bold)
normal=$(tput sgr0)


### Find info.json
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
infojson_exists=false
script_file=`basename "$0"`
if [[ -s "$SCRIPT_DIR/info.json" ]]; then
    infojson_exists=true
else
	cd ..
	if [[ -s "$PWD/info.json" ]]; then
		infojson_exists=true
	else
		cd $SCRIPT_DIR
	fi
fi
mod_folder=$PWD


### Check if sox command exists
### https://sox.sourceforge.net/
sox_exists=false
if command -v ls &> /dev/null; then
	sox_exists=true
fi


SOUNDS_LIST_FILE=sounds_list.lua
CFG_FILE=sounds_list.cfg


### Get mod name and version from info.json
### https://stedolan.github.io/jq/
if [ $infojson_exists = true ] ; then
	MOD_NAME=$(jq -r '.name' info.json)
	if ! command -v jq &> /dev/null; then
		echo "Please install jq https://stedolan.github.io/jq/"
	fi
fi


echo "you're in ${bold}$mod_folder${normal}"

read -r -p "Complete path to folder of sounds: $MOD_NAME/" folder_name
folder_path=$mod_folder/$folder_name
if [ ! -z "$folder_name" ]; then
	rel_folder_path="${folder_name}/"
fi

read -r -p "Add sounds to programmable speakers? [Y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        STATE=1
        ;;
    *)
        STATE=2
        ;;
esac
if [ $STATE -eq 1 ]; then
	read -r -p "Insert group name of sounds:" sound_group_name
	case "$sound_group_name" in "")
		sound_group_name=$MOD_NAME
		;;
	esac
fi


SOUNDS_LIST_PATH="$folder_path/$SOUNDS_LIST_FILE"
rm -f $SOUNDS_LIST_PATH
CFG_FILE="generated_$sound_group_name".cfg
if [ $infojson_exists = true ] ; then
	CFG_FULLPATH=$mod_folder/locale/en/$CFG_FILE
	mkdir -p $mod_folder/locale/en
else
	CFG_FULLPATH=$mod_folder/$CFG_FILE
fi
rm -f $CFG_FULLPATH

if [ $STATE -eq 1 ]; then
	echo "### This file auto-generated by https://github.com/ZwerOxotnik/factorio-example-mod" >> $CFG_FULLPATH
	echo "### Please, do not change this file manually!" >> $CFG_FULLPATH
	echo "[programmable-speaker-instrument]" >> $CFG_FULLPATH
	echo $sound_group_name=$sound_group_name >> $CFG_FULLPATH
	echo "[programmable-speaker-note]" >> $CFG_FULLPATH
fi
echo "-- This file auto-generated by https://github.com/ZwerOxotnik/factorio-example-mod" >> $SOUNDS_LIST_PATH
echo "-- Please, do not change this file if you're not sure, except sounds_list.name and path!" >> $SOUNDS_LIST_PATH
echo "-- You need require this file to your control.lua and add https://mods.factorio.com/mod/zk-lib in your dependencies" >> $SOUNDS_LIST_PATH
echo "" >> $SOUNDS_LIST_PATH
echo "local sounds_list = {" >> $SOUNDS_LIST_PATH

if [ $STATE -eq 1 ]; then
	echo -e "\tname = \"$sound_group_name\", --change me, if you want to add these sounds to programmable speakers" >> $SOUNDS_LIST_PATH
fi
if [ $STATE -eq 2 ]; then
	echo -e "\tname = nil --change me, if you want to add these sounds to programmable speakers" >> $SOUNDS_LIST_PATH
fi
echo -e "\tpath = \"__"${MOD_NAME}"__/"${rel_folder_path}"\", -- path to this folder" >> $SOUNDS_LIST_PATH
echo -e "\tsounds = {" >> $SOUNDS_LIST_PATH


###Converts audio files to .ogg format
if [ $sox_exists = true ] ; then
	files=($(find $folder_path/ -type f))
	for fullpath in "${files[@]}"; do
		### Took from https://stackoverflow.com/a/1403489
		filename="${fullpath##*/}"                      # Strip longest match of */ from start
		dir="${fullpath:0:${#fullpath} - ${#filename}}" # Substring from 0 thru pos of filename
		base="${filename%.[^.]*}"                       # Strip shortest match of . plus at least one non-dot char from end
		ext="${filename:${#base} + 1}"                  # Substring from len of base thru end
		if [[ -z "$base" && -n "$ext" ]]; then          # If we have an extension and no base, it's really the base
			base=".$ext"
			ext=""
		fi
		### It's too messy to fix
		if ! [[ "$ext" =~ ^(|ogg|txt|lua|zip|json|cfg|md|sample|bat|sh|gitignore)$ ]]; then
			sox $fullpath $dir/$base.ogg
		fi
	done
fi

format=*.ogg
files=($(find $folder_path/ -name "$format" -type f))
for path in "${files[@]}"; do
	name="$(basename -- $path)"
	name=${name%.*}
	echo -e "\t\t{" >> $SOUNDS_LIST_PATH
	echo -e "\t\t\tname = \"$name\"", >> $SOUNDS_LIST_PATH
	echo -e "\t\t}," >> $SOUNDS_LIST_PATH
	if [ $STATE -eq 1 ]; then
		echo $name=$name >> $CFG_FULLPATH
	fi
done
echo -e "\t}" >> $SOUNDS_LIST_PATH
echo "}" >> $SOUNDS_LIST_PATH
echo "" >> $SOUNDS_LIST_PATH
echo if "puan_api then puan_api.add_sounds(sounds_list) end" >> $SOUNDS_LIST_PATH
echo "" >> $SOUNDS_LIST_PATH
echo "return sounds_list" >> $SOUNDS_LIST_PATH

echo ""
echo "You're almost ready!${bold}"

if [ ! -s "$SCRIPT_DIR/control.lua" ] && [ $infojson_exists = true ]; then
	echo "require(\"__${MOD_NAME}__/${rel_folder_path}sounds_list\")" >> "$SCRIPT_DIR/control.lua"
else
	if [ $infojson_exists = true ]; then
		echo "# You need to write 'require(\"__${MOD_NAME}__/${rel_folder_path}sounds_list\")' in your ${MOD_NAME}/control.lua"
	else
		echo "# You need to write 'require(\"__mod-name__/${rel_folder_path}sounds_list\")' in your ${MOD_NAME}/control.lua"
	fi
fi
echo "# Add string \"zk-lib\" in dependencies of ${MOD_NAME}/info.json, example: '\"dependencies\": [\"zk-lib\"]'"
if [ $STATE -eq 1 ] && [ $infojson_exists = false ]; then
	echo "# Put ${CFG_FILE} in folder /locale/en (it'll provide readable text in the game)"
fi

echo "${normal}"
echo ""

echo "if you found a bug or you have a problem with script etc, please, let me know"
echo "This script created by ZwerOxotnik (source: https://github.com/ZwerOxotnik/Mod-generator)"
