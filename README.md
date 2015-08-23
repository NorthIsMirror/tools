# Tools

## auto-youtube-dl.sh

A high quality bash script to have simple files instead of multiple youtube-dl
terminal sessions. Create file with URL to the video and forget about any
issues, they will be handled by this script. The queue is intended to be a
Dropbox subdirectory, with the text files, each containing the URL of the video
to download.

Supports Cygwin.

The download will restart many times, at least for 48 hours.

Here is more information on available advanced functions:
  - second line in the queue .txt file can contain youtube-dl options (e.g. -r 100k),
  - you can edit the text file (it will have \*.used extension after the download starts)
  and change the options, and auto-youtube-dl will restart the download. This works
  when there is crontab entry for this script,
  - on third line, you can put BASH commands; they will be executed ahead of the
  download (example: "sleep 120" to defer, "continue" to skip),
  - on last line, auto-youtube-dl will put video's title and duration,
  - each download will be restarted periodically with 15 minutes interval to clean
    out any stalls inside youtube-dl or on the network.

