#!/bin/sh

# convert all m3u8 playlists (UTF-8 encoding) in current dir to m3u (ASCII)
# required for compatibility with some media players
for pl in *.m3u8
  do iconv -f UTF-8 -t ASCII//TRANSLIT "$pl" > "${pl%\.m3u8}.m3u"
  echo "converted $pl"
done