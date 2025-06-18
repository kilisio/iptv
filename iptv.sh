#!/usr/bin/env bash

# dependencies: mpv fzf jq curl gawk

BASEDIR="$(cd "$(dirname "$0")" && pwd)"
rm -rf $BASEDIR/channels/* $BASEDIR/streams/*

# free server port
fuser -k 4242/tcp

# start free channels server
node "$BASEDIR/free_iptv/index.js" &

# select IPTV source
m3uSources=(
  "plex"
  "plutoTv-gb"
  "plutoTv-us"
  "samsungPlus-gb"
  "samsungPlus-us"
  "stirr"
  "PBS"
  "PBSKids"
  "Tubi"
)
m3uUrls=(
  "http://127.0.0.1:4242?region=us&service=Plex"
  "http://127.0.0.1:4242?region=gb&service=PlutoTV"
  "http://127.0.0.1:4242?region=us&service=PlutoTV"
  "http://127.0.0.1:4242?region=gb&service=SamsungTVPlus"
  "http://127.0.0.1:4242?region=us&service=SamsungTVPlus"
  "http://127.0.0.1:4242?region=us&service=Stirr"
  "http://127.0.0.1:4242?region=us&service=PBS"
  "http://127.0.0.1:4242?region=us&service=PBSKids"
  "http://127.0.0.1:4242?region=us&service=Tubi"
)

# select using arrow keys
function print_menu() { # selected_item, ...m3uSources
  local function_arguments=($@)
  local selected_item="$1"
  local m3uSources=(${function_arguments[@]:1})
  local menu_size="${#m3uSources[@]}"

  for ((i = 0; i < $menu_size; ++i)); do
    if [ "$i" = "$selected_item" ]; then
      echo "-> ${m3uSources[i]}"
    else
      echo "   ${m3uSources[i]}"
    fi
  done
}

function run_menu() { # selected_item, ...m3uSources
  local function_arguments=($@)
  local selected_item="$1"
  local m3uSources=(${function_arguments[@]:1})
  local menu_size="${#m3uSources[@]}"
  local menu_limit=$((menu_size - 1))

  clear
  print_menu "$selected_item" "${m3uSources[@]}"

  while read -rsn1 input; do
    case "$input" in
      $'\x1B') # ESC ASCII code (https://dirask.com/posts/ASCII-Table-pJ3Y0j)
        read -rsn1 -t 0.1 input
        if [ "$input" = "[" ]; then # occurs before arrow code
          read -rsn1 -t 0.1 input
          case "$input" in
            A) # Up Arrow
              if [ "$selected_item" -ge 1 ]; then
                selected_item=$((selected_item - 1))
                clear
                print_menu "$selected_item" "${m3uSources[@]}"
              fi
              ;;
            B) # Down Arrow
              if [ "$selected_item" -lt "$menu_limit" ]; then
                selected_item=$((selected_item + 1))
                clear
                print_menu "$selected_item" "${m3uSources[@]}"
              fi
              ;;
          esac
        fi
        read -rsn5 -t 0.1 # flushing stdin
        ;;
      "") # Enter key
        return "$selected_item"
        ;;
    esac
  done
}

selected_item=0
run_menu "$selected_item" "${m3uSources[@]}"
selectedSourceIndex="$?"
echo
url="${m3uUrls[$selectedSourceIndex]}"
# echo $url
cd $BASEDIR/streams
curl -L $url -o "stream.m3u8"

# generate m3u file
m3uFiles=($(ls $BASEDIR/streams/*))
for ((i = 0; i < ${#m3uFiles[@]}; i++)); do
  fileName=$(basename ${m3uFiles[$i]})
  $BASEDIR/m3u.sh $fileName
  rm $fileName
done

# generate streams.json and channels.json files
cd $BASEDIR
npx ts-node parser.ts $url
npm run update

# List IPTV channels
BASH_BINARY="$(which bash)"
TERMV_CACHE_DIR="$BASEDIR/cache"
TERMV_AUTO_UPDATE=${TERMV_AUTO_UPDATE:-true}
TERMV_FULL_SCREEN=${TERMV_FULL_SCREEN:-false}

TERMV_CHANNELS_URL=${TERMV_CHANNELS_URL:-"$BASEDIR/channels/channels.json"}
TERMV_STREAMS_URL=${TERMV_STREAMS_URL:-"$BASEDIR/channels/streams.json"}

FZF_VERSION=$(fzf --version | cut -d '.' -f 2- | cut -d ' ' -f 1)

declare -x TERMV_SWALLOW=${TERMV_SWALLOW:-false}
declare -x TERMV_MPV_FLAGS="${TERMV_DEFAULT_MPV_FLAGS:---no-resume-playback}"

mkdir -p "$TERMV_CACHE_DIR"

# update channels files
printf '%s' "Downloading ${TERMV_CHANNELS_URL:?}... "
mv -f "$BASEDIR/channels/channels.json" "$TERMV_CACHE_DIR/channels_data.json"
printf '\033[32;1m %s \033[0m\n' "Done!"

# update stream files
printf '%s' "Downloading ${TERMV_STREAMS_URL:?}... "
mv -f "$BASEDIR/channels/streams.json" "$TERMV_CACHE_DIR/streams_data.json"
printf '\033[32;1m %s \033[0m\n' "Done!"

# merge json files
jq 'unique_by (.channel) | map({id: .name, url})' "$TERMV_CACHE_DIR/streams_data.json" >"$TERMV_CACHE_DIR/tmp_streams_data.json"
jq 'map({id, name, categories, is_nsfw, languages, country})' "$TERMV_CACHE_DIR/channels_data.json" >"$TERMV_CACHE_DIR/tmp_channels_data.json"
jq -s 'add | group_by(.id) | map(add)' "$TERMV_CACHE_DIR/tmp_streams_data.json" "$TERMV_CACHE_DIR/tmp_channels_data.json" | jq 'map(select ( .url != null ))' >"$TERMV_CACHE_DIR/data.json"
gawk 'NR<2 || NR>5' "$TERMV_CACHE_DIR/data.json" >temp.json && mv temp.json "$TERMV_CACHE_DIR/data.json"
rm "$TERMV_CACHE_DIR/tmp_streams_data.json"
rm "$TERMV_CACHE_DIR/tmp_channels_data.json"

# list channels
[ "${TERMV_SWALLOW}" = true ] && { ! has "xdo" && _pemx "Dependency missing for '-s' flag, please install xdo."; }

[ "${TERMV_FULL_SCREEN}" = true ] && TERMV_MPV_FLAGS="${TERMV_MPV_FLAGS} --fs"

[[ -n "${TERMV_CATEGORY}" ]] && echo "Chosen category: $TERMV_CATEGORY" && TERMV_FILTER="$TERMV_FILTER | select(.categories[0].name == \"$TERMV_CATEGORY\")"
[[ -n "${TERMV_LANGUAGE}" ]] && echo "Chosen language: $TERMV_LANGUAGE" && TERMV_FILTER="$TERMV_FILTER | select(.languages[0].name == \"$TERMV_LANGUAGE\")"
[[ -n "${TERMV_COUNTRY}" ]] && echo "Chosen country: $TERMV_COUNTRY" && TERMV_FILTER="$TERMV_FILTER | select(.countries[0].name == \"$TERMV_COUNTRY\")"

CHANNELS_LIST=$(
  jq -r ".[] $TERMV_FILTER | \"\(.id) \t \(.categories[]? // \"N/A\") \t \(.languages[]? // \"N/A\") \t \(.country? // \"N/A\") \t \(.url)\"" "$TERMV_CACHE_DIR/data.json" |
    gawk -v max="${COLUMNS:-80}" 'BEGIN { RS="\n"; FS=" \t " }
                    {
                      name = substr(gensub(/[0-9]+\.\s*(.*)/, "\\1", "g", $1),0,max/4)
                      category = substr(gensub(/\s+> (.*)/, "\\1", "g", $2),0,max/8)
                      languages = substr(gensub(/\s+> (.*)/, "\\1", "g", $3),0,max/8)
                      countries = substr(gensub(/\s+> (.*)/, "\\1", "g", $4),0,70)
                      channelUrl = substr(gensub(/\s+> (.*)/, "\\1", "g", $5),0)
                      print name "\t|" category "\t|" languages "\t|" countries "\t" channelUrl
                    }' | column -t -s $'\t'
)

_play() {
  printf '%s\n' "Fetching channel, please wait..."
  if [ "${TERMV_SWALLOW}" = true ]; then
    WID=$(xdo id)
    xdo hide
    # shellcheck disable=SC2086
    # mpv "${*##* }" ${TERMV_MPV_FLAGS} --force-media-title="${*%%  *}" --force-window=immediate
    streamlink "${*##* }" "432p,480p,540p,576p,640p,360p,432p_alt,480p_alt,540p_alt,576p_alt,640p_alt,360p_alt,300k,600k,900k,1000k,1600k,2300k,720p,720p_alt,best" --mux-subtitles --ringbuffer-size 64M -p mpv -a "${TERMV_MPV_FLAGS} --force-media-title='${*%%  *}'  --force-window=immediate" --hls-audio-select "*"
    xdo show "$WID" && xdo activate "$WID"
  else
    # shellcheck disable=SC2086
    # mpv "${*##* }" ${TERMV_MPV_FLAGS} --force-media-title="${*%%  *}"
    streamlink "${*##* }" "432p,480p,540p,576p,640p,360p,432p_alt,480p_alt,540p_alt,576p_alt,640p_alt,360p_alt,300k,600k,900k,1000k,1600k,2300k,720p,720p_alt,best" --ringbuffer-size 64M --mux-subtitles -p mpv -a "${TERMV_MPV_FLAGS} --force-media-title='${*%%  *}'" --hls-audio-select "*"
  fi
}

_playbg() {
  { setsid -f mpv "${*##* }" ${TERMV_MPV_FLAGS} --force-media-title="${*%%  *}" --force-window=immediate >/dev/null 2>&1; }
}

export -f _play
export -f _playbg

if [ $(echo "$FZF_VERSION < 25.0" | bc) == 1 ]; then
  SHELL="${BASH_BINARY}" \
    fzf -e -i --reverse --cycle --with-nth="1..-2" \
    --bind "enter:execute(_play {})" \
    --bind "double-click:execute(_play {})" \
    --header="Select channel (press Escape to exit)" -q "${*:-}" \
    < <(printf '%s\n' "${CHANNELS_LIST}")
else
  SHELL="${BASH_BINARY}" \
    fzf -e -i --reverse --cycle --with-nth="1..-2" \
    --bind "alt-]:execute-silent(_playbg {})" \
    --bind "enter:execute(_play {})" \
    --bind "double-click:execute(_play {})" \
    --header="Select channel (press Escape to exit)" -q "${*:-}" \
    < <(printf '%s\n' "${CHANNELS_LIST}")
fi
