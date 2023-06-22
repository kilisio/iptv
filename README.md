# ABOUT

<!-- ## Homepage -->


## Description
A simple IPTV terminal tool based on:

>termv: https://github.com/Roshan-R/termv.git

and

>iptv-org: https://github.com/iptv-org/iptv.git

### Requirements

1. mpv video player should be installed in the pc (linux)

2. install and setup yt-dlp in mpv for better streaming. I have included basic mpv config below (optional)

### How to:
    git clone https://github.com/kilisio/iptv.git
    cd iptv
    npm install
    ./iptv.sh

### Configs

```bash
# mpv.conf
script-opts-append=ytdl_hook-ytdl_path=yt-dlp
script-opts-append=ytdl_hook-try_ytdl_first=yes
cache=no
ytdl-format=[height<=480][width<=720]
untimed=yes

# .bashrc
export TERMV_DEFAULT_MPV_FLAGS="--no-resume-playback --cache=no --hwdec=no --ytdl-format=[height<=480][width<=720]"

```


# LICENSE
Copyright © 2023 Patrick Kilisio.

