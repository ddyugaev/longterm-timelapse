#!/usr/bin/env bash
set -eux -o pipefail

#Script Folder
script_folder=/opt/longterm-timelapse

#Load config
source $script_folder/config.txt

#Write to log file
exec > $log_file 2>&1

#Creating temp folder
if [ ! -d "$working_dir/temp" ]
then
    /usr/bin/mkdir -p "$working_dir"/temp
fi

touch "$working_dir/counter.txt"

# Define a timestamp function
timestamp() {
  date +"%T" # current time
}

#Check for dependencies
function dependencies_check {

    dependencies=("$gphoto2_path" "pnmtojpeg" "dcraw")
    not_installed=()

    for i in "${dependencies[@]}"
    do
        if ! [ -x "$(command -v $i)" ]; then
            not_installed+=("$i")
        fi
    done

    if [ ${#not_installed[@]} -eq 0 ]; then
        timestamp
        echo "All dependencies installed"
    else
        timestamp
        echo "Please install following binaries and rerun this script"
        echo "-------------------------------------------------------"
        for i in "${not_installed[@]}"
        do
            if [ $i = $gphoto2_path ]; then
                printf "sudo apt install snapd\nsudo snap install gphoto2\n"
            fi
            if [ $i = pnmtojpeg ]; then
                echo "sudo apt install netpbm"
            fi
            if [ $i = dcraw ]; then
                echo "sudo apt install dcraw"
            fi
        done
        echo "-------------------------------------------------------"
        exit 1
    fi
}

function send_picture {
    echo "Send picture"
    chat="$1"
    picture="$2"
    # https://stackoverflow.com/questions/56865217/php-curl-error-http-2-stream-0-was-not-closed-cleanly-protocol-error-err-1
    # check the link above about http v1.1
    /usr/bin/curl --http1.1 -s -X POST "https://api.telegram.org/bot$token/sendPhoto" -F chat_id="$chat" -F photo="@$picture"
}

function send_message {
    echo "Send message"
    chat="$1"
    message="$2"
    /usr/bin/curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" -d  "chat_id=$chat&text=$message"
}

#Get pictures from camera
function camera_sync {
    timestamp
    echo "Syncing photos from camera"
    cd "$working_dir"
    $gphoto2_path --get-all-files --skip-existing
    timestamp
    echo "Finish: Syncing photos from camera"
}

function convert_raw_to_jpeg {
    timestamp
    echo "Converting RAW to JPG"
    #picture=$(ls -la "$working_dir" | grep CR2 | tail -1 | cut -d ' ' -f 11)
    picture=0
    #unset -v picture
    for file in "$working_dir"/*.CR2; do
        [[ $file -nt $picture ]] && picture=$file
    done
    /usr/bin/cp "$picture" "$raw_picture"
    echo "$picture"
    /usr/bin/dcraw -c "$raw_picture" | pnmtojpeg > "$preview"
    #sleep 30
    timestamp
    echo "Finish: Converting RAW to JPG"
}

function check_size {
    echo "Checking folder size"
    target="$1"
    folder_size=$(du -sh "$target" | cut -f1 -d$'\t')
    free_space=$(df -H --output=avail / | tail -1)
}

function counter {
    echo "Start: Counting pictures"
    new=$( $gphoto2_path --list-files | grep "$camera_folder" | cut -d ' ' -f 3 )
    old=$( cat $script_folder/counter.txt )

    if [ -z "$new" ]
    then
        send_message $telegram_chatid "ERROR: [$camera_name] NO connection to camera - $new"
    elif [ "$new" = "$old" ]
    then
        send_message $telegram_chatid "ERROR: [$camera_name] NO new photos have been taken - $new"
    else
        send_message $telegram_chatid "[$camera_name] $new photos have been taken"
        echo "$new" > $script_folder/counter.txt
    fi
    echo "Finish: Counting pictures"
}

function cleanup {
    echo "Cleaning up"
    rm $raw_picture
    rm $preview
    echo "Finish: Cleaning up"
}

cron=$(pstree -s $$ | grep -q cron && echo true || echo false)

if $cron
then
    echo "Being run by cron"
else
    echo "Not being run by cron"
    dependencies_check
fi

check_size "$working_dir" \
&& camera_sync \
&& convert_raw_to_jpeg \
&& send_picture "$telegram_chatid" "$preview" \
&& counter \
&& send_message "$telegram_chatid" "Photo folder size - $folder_size%0AFree space on SD -$free_space" \
&& cleanup
