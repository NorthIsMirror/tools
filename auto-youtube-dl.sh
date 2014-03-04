#!/bin/sh

export PATH=$PATH:/usr/local/bin:/usr/local/sbin

BDIR="$HOME"
BDIR2="$USERPROFILE"

#
# Much below is an approach to make you change name of directories
# instead of defining paths.
#
# If you have your Dropbox (Google, etc.) directory in /usr/local/var/Dropbox
# or similar fussy location, then you will know what to do anyway (hint: change
# BDIR* to /usr/local/var)
#
# The difficulty is Windows - Unix portability. This is the cause for
# existence of BDIR and BDIR2.
#
# You should need only to define:
# - CLOUD_DIR
# - QUEUE_SUBDIR
# - VIDEO_DOWNLOAD_SUBDIR
# - optional: MOVE_AFTER_DOWNLOAD_PATH
#
# The rest will be deduced and created in your Windows/Unix user directory
#

# *_DIR: relative to $HOME and then to %USERPROFILE%, i.e. to $BDIR, $BDIR2
# *_SUBDIR: relative to corresponding DIR
# *_PATH: absolute path

# As ever: searched for in $BDIR, then $BDIR2
CLOUD_DIR="Dropbox"
# Under CLOUD_DIR. Holds the .txt with the URL to download
QUEUE_SUBDIR="var/youtube-dl"

# As ever: $BDIR/*, then $BDIR2/*
# (four combinations)
VIDEO_DOCUMENTS_DIR="Movies"
VIDEO_DOCUMENTS_DIR2="Videos"
# Under $VIDEO_DOCUMENTS_DIR* (the first one found)
# This is the target download directory
VIDEO_DOWNLOAD_SUBDIR="youtube"

# Move fully downloaded file into this path
MOVE_AFTER_DOWNLOAD_PATH=""

#
# 1. Establish queue dir
#

if [ -d "$BDIR/$CLOUD_DIR" ]; then
    QUEUE_PATH="$BDIR/$CLOUD_DIR/$QUEUE_SUBDIR"
elif [ -d "$BDIR2/$CLOUD_DIR" ]; then
    QUEUE_PATH="$BDIR2/$CLOUD_DIR/$QUEUE_SUBDIR"
else
    echo "Error: no cloud dir '$CLOUD_DIR' found either in '$BDIR' or '$BDIR2'"
    exit 1
fi

mkdir -p "$QUEUE_PATH"

#
# 2. Establish destination download dir
#

if [ -d "$BDIR/$VIDEO_DOCUMENTS_DIR/$VIDEO_DOWNLOAD_SUBDIR" ]; then
    OUTPUT_VIDEO_PATH="$BDIR/$VIDEO_DOCUMENTS_DIR/$VIDEO_DOWNLOAD_SUBDIR"
elif [ -d "$BDIR2/$VIDEO_DOCUMENTS_DIR/$VIDEO_DOWNLOAD_SUBDIR" ]; then
    OUTPUT_VIDEO_PATH="$BDIR2/$VIDEO_DOCUMENTS_DIR/$VIDEO_DOWNLOAD_SUBDIR"
else
    if [ -d "$BDIR/$VIDEO_DOCUMENTS_DIR" ]; then
        OUTPUT_VIDEO_PATH="$BDIR/$VIDEO_DOCUMENTS_DIR/$VIDEO_DOWNLOAD_SUBDIR"
    elif [ -d "$BDIR2/$VIDEO_DOCUMENTS_DIR" ]; then
        OUTPUT_VIDEO_PATH="$BDIR2/$VIDEO_DOCUMENTS_DIR/$VIDEO_DOWNLOAD_SUBDIR"
    else
        if [ -d "$BDIR/$VIDEO_DOCUMENTS_DIR2/$VIDEO_DOWNLOAD_SUBDIR" ]; then
            OUTPUT_VIDEO_PATH="$BDIR/$VIDEO_DOCUMENTS_DIR2/$VIDEO_DOWNLOAD_SUBDIR"
        elif [ -d "$BDIR2/$VIDEO_DOCUMENTS_DIR2/$VIDEO_DOWNLOAD_SUBDIR" ]; then
            OUTPUT_VIDEO_PATH="$BDIR2/$VIDEO_DOCUMENTS_DIR2/$VIDEO_DOWNLOAD_SUBDIR"
        else
            if [ -d "$BDIR/$VIDEO_DOCUMENTS_DIR2" ]; then
                OUTPUT_VIDEO_PATH="$BDIR/$VIDEO_DOCUMENTS_DIR2/$VIDEO_DOWNLOAD_SUBDIR"
            elif [ -d "$BDIR2/$VIDEO_DOCUMENTS_DIR2" ]; then
                OUTPUT_VIDEO_PATH="$BDIR2/$VIDEO_DOCUMENTS_DIR2/$VIDEO_DOWNLOAD_SUBDIR"
            else
                echo "No video dir '$VIDEO_DOCUMENTS_DIR' or '$VIDEO_DOCUMENTS_DIR2' found in '$BDIR' and '$BDIR2'"
                echo "And no download dir '$VIDEO_DOWNLOAD_SUBDIR' could be created"
                exit 1
            fi
        fi
        mkdir -p "$OUTPUT_VIDEO_PATH"
    fi
fi

echo QUEUE_PATH: $QUEUE_PATH
echo OUTPUT_VIDEO_PATH: $OUTPUT_VIDEO_PATH

# This is minimum 48 hours of waiting for re-download
# (plus the time of actual downloading)
MAXRETRIES=$(( 2 * 18 * 24 ))
RETRY=0
SLTIME=200

function move_finished {
    if [ "$MOVE_AFTER_DOWNLOAD_PATH" = "" ]; then
        return
    fi

    if [ ! -d "$MOVE_AFTER_DOWNLOAD_PATH" ]; then
        return
    fi

    cd $OUTPUT_VIDEO_PATH || return

    {
        mv -vf *.mp4 "$MOVE_AFTER_DOWNLOAD_PATH"
        mv -vf *.flv "$MOVE_AFTER_DOWNLOAD_PATH"
    }
}

move_finished

ALREADY_RUNNING=`ps -ae | grep -v grep | egrep -c '.*sh.*-c.*auto-youtube-dl.*'`
(( ALREADY_RUNNING = ALREADY_RUNNING + 0 ))
if [[ $ALREADY_RUNNING -gt 3 ]]; then
    echo "To much downloads ($ALREADY_RUNNING), exiting"
    exit
fi

NO_PROGRESS="--no-progress"
if [ "$1" = "-v" ]; then
    NO_PROGRESS=""
fi

cd "$OUTPUT_VIDEO_PATH"

# Iterate over txt fils inside $QUEUE_PATH
for queue_file in $QUEUE_PATH/*.txt; do
    [ -f $queue_file ] || break

    video_url=$(<$queue_file)
    mv -vf "$queue_file" "${queue_file%.txt}.used"
    echo -e "\n$queue_file : $video_url\n"

    while (( RETRY ++ < MAXRETRIES )); do
        echo "(re-)Starting download with the command: " youtube-dl $NO_PROGRESS -f "18/22/35/34/h264-sd/h264-hd" --restrict-filenames -o "$OUTPUT_VIDEO_PATH"/'%(title)s.%(ext)s' "$video_url"
        if youtube-dl $NO_PROGRESS -f "18/22/35/34/h264-sd/h264-hd" --restrict-filenames -o "$OUTPUT_VIDEO_PATH"/'%(title)s.%(ext)s' "$video_url"; then
            echo "Download succesfull"
            break
        else
            echo "`date` Download falied at retry $RETRY / $MAXRETRIES"
            sleep $SLTIME
        fi
    done
done

move_finished

exit 0

