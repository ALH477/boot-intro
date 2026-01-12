#!/usr/bin/env bash
# DeMoD LLC - Boot Intro Preview Utility
# Usage: ./preview-intro.sh [title] [bottom_text] [logo_path]

TITLE="${1:-Welcome to NixOS}"
BOTTOM="${2:-Powered by DeMoD LLC}"
LOGO="${3:-./logo.png}"
BG_VIDEO="./background.mp4" # Set to an actual path or leave empty
RES="2560x1600"
OPACITY="0.8"

# Check dependencies
for cmd in ffmpeg ffprobe mpv bc; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required. Run in a nix-shell or install the package."
        exit 1
    fi
done

# Assuming a test audio file exists for the preview
AUDIO_IN="./test_audio.wav"
if [ ! -f "$AUDIO_IN" ]; then
    echo "Error: test_audio.wav not found. Please provide an audio sample."
    exit 1
fi

# Calculate fade timings
TOTAL_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_IN")
FADE_START=$(echo "$TOTAL_DUR - 1.5" | bc -l)

echo "Rendering preview for: $TITLE..."

# Build the filter graph
FF_FILTERS="[0:a]asplit=2[viz_a][final_a]; \
[final_a]afade=t=out:st=$FADE_START:d=1.5[aout]; \
[viz_a]asplit=2[l][r]; \
[l]showwaves=s=$RES:mode=cline:colors=#00FF88:scale=cbrt:draw=full[lw]; \
[r]showwaves=s=$RES:mode=cline:colors=#00FF88:scale=cbrt:draw=full,vflip[rw]; \
[lw][rw]overlay=0:(H-h)/2,hue=s=1.8,split=2[base][bloom]; \
[bloom]gblur=sigma=8[blur]; \
[base][blur]blend=all_mode=screen,lenscorrection=k1=0.12:k2=0.08,vignette='PI/5',format=rgba,colorchannelmixer=aa=$OPACITY[viz_v];"

# Add Background logic
if [ -f "$BG_VIDEO" ]; then
    INPUTS="-i $AUDIO_IN -stream_loop -1 -i $BG_VIDEO"
    FF_FILTERS+="[1:v]scale=$RES:force_original_aspect_ratio=increase,crop=$RES[bg]; [bg][viz_v]overlay=0:0:shortest=1[comp];"
else
    INPUTS="-i $AUDIO_IN -f lavfi -i color=c=black:s=$RES"
    FF_FILTERS+="[1:v][viz_v]overlay=0:0:shortest=1[comp];"
fi

# Add Logo and Text
INPUTS+=" -i $LOGO"
FF_FILTERS+="[2:v][comp]scale2ref=w=oh*0.35:h=oh*0.35:force_original_aspect_ratio=decrease[logo][bg_ref]; \
[bg_ref][logo]overlay=(W-w)/2:(H-h)/2, \
drawtext=text='$TITLE':fontcolor=#00FF88:fontsize=h/18:x=(w-text_w)/2:y=h/10:shadowcolor=black@0.8:shadowx=4:shadowy=4, \
drawtext=text='$BOTTOM':fontcolor=#00FF88:fontsize=h/28:x=(w-text_w)/2:y=h-text_h-h/12:shadowcolor=black@0.8:shadowx=4:shadowy=4, \
fade=t=out:st=$FADE_START:d=1.5:color=black[vout]"

# Play immediately without saving to disk
ffmpeg -hide_banner -loglevel error $INPUTS -filter_complex "$FF_FILTERS" -map "[vout]" -map "[aout]" -f matroska - | mpv -
