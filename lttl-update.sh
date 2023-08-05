#!/usr/bin/env bash

script_folder=/opt/longterm-timelapse
branch=$(git branch --show-current)

function update {
    local a=${1%%.*} b=${2%%.*}
    if [[ "10#${a:-0}" -lt "10#${b:-0}" ]]; then
        echo "Updating the script"
        cd $script_folder
        git checkout -- .
        git pull
    fi
    a=${1:${#a} + 1} b=${2:${#b} + 1}
    [[ -z $a && -z $b ]] || update "$a" "$b"
}

current_version=$(cat $script_folder/version.txt)
online_version=$(curl -s https://raw.githubusercontent.com/ddyugaev/longterm-timelapse/${branch}/version.txt)
update $current_version $online_version
