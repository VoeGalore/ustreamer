#!/bin/bash

### ustreamer source and build instructions:
### https://github.com/pikvm/ustreamer?tab=readme-ov-file#building

echo "
 This script attempts to:
  1. Clone ustreamer from official repo https://github.com/pikvm/ustreamer
  2. Make changes to /src/libs/drm/drm.c base on your board type
  3. Compile and install ustreamer

**Make sure you enabled read-write mode and use elevated permission!**
 "

read -p "Do you want to run the script? [y/N]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
        then
        echo "
 Running script...
 "

        boardtype="`tr < /sys/firmware/devicetree/base/compatible -d '\000'`"

        # clone ustreamer from official repo
        git clone --depth=1 https://github.com/pikvm/ustreamer
        echo "
 Checking board type...
 "
        case $boardtype in
                        "raspberrypi,3"*)
                                        echo "Board is RPi 3 variant (A/B/+)
                                        ";
                                        sed -i 's/platform-gpu-card/platform-soc:gpu-card/g' ./ustreamer/src/libs/drm/drm.c;
                                        sed -i 's/HDMI-A-2/HDMI-A-1/g' ./ustreamer/src/libs/drm/drm.c;
                                        sed -i 's/OUT2 on PiKVM V4 Plus/HDMI0 on Pi3/g' ./ustreamer/src/libs/drm/drm.c
                                        ;;
                        "raspberrypi,4"*)
                                        echo "Board is RPi 4 variant (4B/CM4)
                                        ";
                                        sed -i 's/HDMI-A-2/HDMI-A-1/g' ./ustreamer/src/libs/drm/drm.c;
                                        sed -i 's/OUT2 on PiKVM V4 Plus/HDMI0 on Pi4 or OUT1 on PiKVM V4 Plus/g' ./ustreamer/src/libs/drm/drm.c
                                        ;;
                        *)
                                        echo "Board is neither Pi 3 nor Pi 4 variants. Script aborted!"; exit 1;;
         esac

        # Installing prerequisites (default PiKVM OS on Arch Linux, including DIY versions)
        #pacman -S libevent libjpeg-turbo libutil-linux libbsd

        cd ./ustreamer
        make clean
        make WITH_GPIO=1 WITH_SYSTEMD=1 WITH_JANUS=1 WITH_V4P=1
        make install
        cd ..

        # create symbolic links to allow kvmd use the custome ustreamer without override
        echo "
 Creating symbolic links for newly installed ustreamer binary..."
        ln -sf /usr/local/bin/ustreamer /usr/bin/
        ln -sf /usr/local/bin/ustreamer-dump /usr/bin/
        echo " Done!"
        echo '
Make changes to your /etc/kvmd/override.yaml file:
########################################
kvmd:
    streamer:
        forever: true
        cmd_append:
            - "--format-swap-rgb"
            - "--buffers=8"
            - "--format=rgb24"
            - "--encoder=cpu"
            - "--v4p"
########################################

Then run:
        systemctl restart kvmd

And you will be able to use HDMI0 port for passthrough.'

        else echo "
 Script aborted!
 "; exit 0
fi
exit 0
