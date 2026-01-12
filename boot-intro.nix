{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.boot-intro;

  # --- Configuration & Helpers ---
  fadeDurationSecs = "1.5"; # Duration of the fade out at the end

  escapeText = text: replaceStrings ["'" ":"] ["\\'" "\\:"] text;
  escapedTitle = escapeText cfg.titleText;
  escapedBottom = escapeText cfg.bottomText;

  soundFontFile = config.services.boot-sound.soundFontFile or "${pkgs.fluid-soundfont-gm}/share/soundfonts/FluidR3_GM.sf2";
  soundGain = config.services.boot-sound.gain or 3.0;

  logoPath = cfg.logoImage;
  logoExt = if logoPath != null
            then lib.toLower (lib.last (lib.splitString "." (baseNameOf logoPath)))
            else null;
  isGif = (logoExt == "gif");

  hasBackgroundVideo = cfg.backgroundVideo != null;
  hasLogo = cfg.logoImage != null;

  # --- Video Generation Derivation ---
  generatedVideo = pkgs.stdenv.mkDerivation {
    name = "boot-intro-video.mp4";
    # We need 'bc' for floating point math to calculate fade timings
    buildInputs = [ pkgs.ffmpeg-full pkgs.fluidsynth pkgs.dejavu_fonts pkgs.bc ];
    buildCommand = ''
      # 1. Generate/Copy Audio
      echo "Generating audio..."
      if [[ "${config.services.boot-sound.soundFile}" =~ \.(mid|midi)$ ]]; then
        fluidsynth -ni "${soundFontFile}" "${config.services.boot-sound.soundFile}" -F audio.wav -r 48000 -g ${toString soundGain}
      else
        cp "${config.services.boot-sound.soundFile}" audio.wav
      fi

      # 2. Calculate Durations for Fades
      # Get total duration of generated audio using ffprobe
      TOTAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 audio.wav)
      # Calculate start time for the fade out using bc (Total - Fade Duration)
      FADE_START=$(echo "$TOTAL_DURATION - ${fadeDurationSecs}" | bc -l)
      echo "Video Duration: $TOTAL_DURATION. Fade starting at: $FADE_START"

      # 3. Render Video with Fades
      ffmpeg -y -i audio.wav \
        ${optionalString hasBackgroundVideo "-stream_loop -1 -i ${cfg.backgroundVideo}"} \
        ${optionalString (!hasBackgroundVideo) "-f lavfi -i color=c=black:s=${cfg.baseResolution}"} \
        ${optionalString hasLogo "${if isGif then "-ignore_loop 0" else ""} -i ${cfg.logoImage}"} \
        -filter_complex "\
          [1:v]scale=${cfg.baseResolution}:force_original_aspect_ratio=increase,crop=${cfg.baseResolution}[vbgscaled]; \
          \
          [0:a]asplit=2[audio_viz][audio_final_raw]; \
          [audio_final_raw]afade=t=out:st=$FADE_START:d=${fadeDurationSecs}[audio_out]; \
          \
          [audio_viz]asplit=2[left][right]; \
          [left]showwaves=s=${cfg.baseResolution}:mode=cline:colors=#00FF88:scale=cbrt:draw=full[lw]; \
          [right]showwaves=s=${cfg.baseResolution}:mode=cline:colors=#00FF88:scale=cbrt:draw=full[rw]; \
          [rw]vflip[rwf]; \
          [lw][rwf]overlay=0:(main_h-overlay_h)/2[sym]; \
          [sym]hue=s=1.8[sat]; \
          [sat]split=2[base][bloom]; \
          [bloom]gblur=sigma=8[bloomblur]; \
          [base][bloomblur]blend=all_mode=screen:shortest=1[glow]; \
          [glow]lenscorrection=cx=0.5:cy=0.5:k1=0.12:k2=0.08[curved]; \
          [curved]geq='lum(X,Y)*(0.8 + 0.2*cos(PI*Y/2))'[scanned]; \
          [scanned]vignette='PI/5',format=rgba,colorchannelmixer=aa=${toString cfg.waveformOpacity}[viz]; \
          [vbgscaled][viz]overlay=0:0:shortest=1[bgwithviz]; \
          ${optionalString hasLogo ''
            [2:v][bgwithviz]scale2ref=w=oh*0.35:h=oh*0.35:force_original_aspect_ratio=decrease[logoscaled][bg_ref];
            [bg_ref][logoscaled]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[combined];
          ''} \
          [${if hasLogo then "combined" else "bgwithviz"}] \
            drawtext=text='${escapedTitle}':fontfile=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf:fontcolor=#00FF88:fontsize=h/18:x=(w-text_w)/2:y=h/10:shadowcolor=black@0.8:shadowx=4:shadowy=4, \
            drawtext=text='${escapedBottom}':fontfile=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf:fontcolor=#00FF88:fontsize=h/28:x=(w-text_w)/2:y=h-text_h-h/12:shadowcolor=black@0.8:shadowx=4:shadowy=4 \
            [texted_video]; \
          [texted_video]fade=t=out:st=$FADE_START:d=${fadeDurationSecs}:color=black[video_out] \
        " -map "[video_out]" -map "[audio_out]" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -shortest $out
    '';
  };

  finalVideoPath = if cfg.videoFile != null then cfg.videoFile else generatedVideo;
in
{
  options.services.boot-intro = {
    enable = mkEnableOption "Boot intro video compatible with X11 and Wayland";
    videoFile = mkOption { type = types.nullOr types.path; default = null; description = "Pre-rendered video path. Fades are not applied if this is set."; };
    titleText = mkOption { type = types.str; default = "Welcome to NixOS"; };
    bottomText = mkOption { type = types.str; default = "Powered by DeMoD LLC"; };
    logoImage = mkOption { type = types.nullOr types.path; default = null; };
    backgroundVideo = mkOption { type = types.nullOr types.path; default = null; };
    waveformOpacity = mkOption { type = types.float; default = 0.8; };
    baseResolution = mkOption { type = types.str; default = "2560x1600"; };
    fillMode = mkOption {
      type = types.enum [ "fill" "letterbox" "fit" ];
      default = "fill";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.mpv ];

    # Systemd service runs on TTY for cross-protocol compatibility
    systemd.services.boot-intro-player = {
      description = "Play Boot Intro Video";
      after = [ "systemd-user-sessions.service" "plymouth-quit-wait.service" "getty@tty1.service" ];
      before = [ "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];
      
      unitConfig = {
        Conflicts = [ "getty@tty1.service" ];
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          pancrop = if cfg.fillMode == "fill" then "--panscan=1.0" 
                    else if cfg.fillMode == "letterbox" then "--no-panscan" 
                    else "--autofit-larger=100%";
        in "${pkgs.mpv}/bin/mpv \
          --fs --no-border --no-config --no-osd-bar --no-input-default-bindings \
          --vo=gpu --gpu-context=auto --hwdec=auto-safe \
          ${pancrop} --scale=ewa_lanczossharp \
          ${finalVideoPath}";
        StandardOutput = "tty";
        StandardInput = "tty";
        TTYPath = "/dev/tty1";
      };
    };

    # Ensure SDDM/GDM doesn't clear the screen too early
    services.displayManager.sddm.extraConfig = optionalString (config.services.displayManager.sddm.enable) ''
      [General]
      InputMethod=
    '';
  };
}
