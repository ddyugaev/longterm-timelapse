#!/usr/bin/env bash

script_folder=/opt/longterm-timelapse
script_folder=/Users/ddyugaev/Projects/longterm-timelapse

function update {
    local a=${1%%.*} b=${2%%.*}
    if [[ "10#${a:-0}" -lt "10#${b:-0}" ]]; then
        #cd $script_folder
        #git remote prune origin
        #git fetch origin
        echo "git pull"
    fi
    a=${1:${#a} + 1} b=${2:${#b} + 1}
    [[ -z $a && -z $b ]] || update "$a" "$b"
}

current_version=$(cat $script_folder/version.txt)
online_version=$(curl -s https://raw.githubusercontent.com/ddyugaev/longterm-timelapse/main/version.txt)
update $current_version $online_version
