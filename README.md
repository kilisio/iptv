# ABOUT
A simple IPTV terminal tool based on:

>termv: https://github.com/Roshan-R/termv.git

and

>iptv-org: https://github.com/iptv-org/iptv.git

## Requirements

1. mpv video player should be installed in the pc (linux)

2. install and setup yt-dlp in mpv for better streaming. I have included basic mpv config below (optional)

## How to:
    git clone https://github.com/kilisio/iptv.git
    cd iptv
    npm install
    ./iptv.sh

## Configs

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

# Legal

No video files are stored in this repository. The repository simply contains links to publicly available video stream URLs, which to the best of our knowledge have been intentionally made publicly by the copyright holders. If any links in this repo infringe on your rights as a copyright holder, they may be removed by opening an issue. However, note that we have no control over the destination of the link, and just removing the link from the playlist will not remove its contents from the web. Note that linking does not directly infringe copyright because no copy is made on the site providing the link, and thus this is not a valid reason to send a DMCA notice to GitHub. To remove this content from the web, you should contact the web host that's actually hosting the content (not GitHub, nor the maintainers of this 


# LICENSE
Copyright © 2023 Patrick Kilisio.

