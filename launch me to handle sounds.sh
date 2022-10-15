#!/bin/bash
### Generates lua and cfg files to handle .ogg sounds for Factorio


### Find info.json
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
infojson_exists=false
script_file=`basename "$0"`
if [[ -f "$SCRIPT_DIR/info.json" ]]; then
    infojson_exists=true
else
	cd ..
	if [[ -f "$PWD/info.json" ]]; then
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
if [ infojson_exists = true ] ; then
	mod_name=`cat info.json|jq -r .name`
fi


echo "you're in $SCRIPT_DIR"
read -r -p "Complete path to folder of sounds: $mod_name/" folder_path 
folder_path=$mod_folder/$folder_path
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
		sound_group_name=$mod_name
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
echo -e "\tpath = \"__"$mod_name"__/"$folder_path"/\", -- path to this folder" >> $SOUNDS_LIST_PATH
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
		if ! [[ "$ext" =~ ^(|ogg|txt|lua|zip|json|cfg|md|sample|bat|sh)$ ]]; then
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

echo "You're almost ready!"
echo "# You need to write 'require(\"__$mod_name__/$folder_path/sounds_list\")' in your $mod_name/control.lua"
echo "# Add string \"zk-lib\" in dependencies of $mod_name/info.json, example: '\"dependencies\": [\"zk-lib\"]'"
if [ $STATE -eq 1 ] && [ $infojson_exists = false ]; then
	echo "# Put $CFG_FILE in folder "$mod_name"/locale/en (it'll provide readable text in the game)"
fi

echo ""
echo ""

echo "if you found a bug or you have a problem with script etc, please, let me know"
echo "This script created by ZwerOxotnik (source: https://github.com/ZwerOxotnik/Mod-generator)"
