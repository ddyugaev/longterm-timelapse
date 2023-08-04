
# Longterm Timelapse

Script which pulls photos from the camera and sends preview and stats to telegram

**What `lttl.sh` script does:**
* Runs lttl-run.sh and lttl-update.sh scripts

**What `lttl-run.sh` script does:**
* Copies photos from camera
* Checks if new picture has been taking from the last run
* Sends preview of last picture taken and status to telegram

**What `lttl-update.sh` script does:**
* Checks github repo for updates and updates

**Installation:**

Create directory  
`sudo mkdir -p /opt/longterm-timelapse`  
`cd /opt/`  
Clone git repository  
`sudo git clone https://github.com/ddyugaev/longterm-timelapse.git`  
Make scripts executable  
`sudo chmod +x /opt/longterm-timelapse/*.sh`  
Copy config_example.txt to config.txt  
`sudo cp /opt/longterm-timelapse/config_example.txt /opt/longterm-timelapse/config.txt`  
Edit config  
`sudo vim /opt/longterm-timelapse/config.txt`  
Add Crontab  
`crontab -e`  
`00 09 * * * /opt/longterm-timelapse/lttl.sh`  
See https://crontab.guru/

**Troubleshoot**

To fix problem with gvfs `gphoto2: Could not claim the USB device`  
Stop gvfs-gphoto2-volume-monitor and gvfsd-gphoto2  
`pkill gphoto2`  

To start both services run:  
`systemctl --user start gvfs-gphoto2-volume-monitor`  
`/usr/lib/gvfs/gvfsd-gphoto2`  

To disable autostart  
`sudo chmod -x /usr/lib/gvfs/gvfsd-gphoto2`  
`sudo chmod -x /usr/lib/gvfs/gvfs-gphoto2-volume-monitor`  

**Tested on**  
Raspbian GNU/Linux 11 (bullseye)  
Canon 7D  