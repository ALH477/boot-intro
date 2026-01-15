{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.boot-intro;

  # --- Helpers ---
  fadeDurationSecs = "1.5"; # Duration of the fade out

  escapeText = text: replaceStrings ["'" ":"] ["\\'" "\\:"] text;
  escapedTitle = escapeText cfg.titleText;
  escapedBottom = escapeText cfg.bottomText;

  # Logic to handle different audio types (MIDI vs generic audio)
  logoPath = cfg.logoImage;
  logoExt = if logoPath != null
            then lib.toLower (lib.last (lib.splitString "." (baseNameOf logoPath)))
            else null;
  isGif = (logoExt == "gif");

  hasBackgroundVideo = cfg.backgroundVideo != null;
  hasLogo = cfg.logoImage != null;

  # --- Video Generation Derivation ---
  # This builds the video once during system rebuild
  generatedVideo = pkgs.stdenv.mkDerivation {
    name = "boot-intro-video.mp4";
    buildInputs = [ pkgs.ffmpeg-full pkgs.fluidsynth pkgs.dejavu_fonts pkgs.bc ];
    
    buildCommand = ''
      # 1. Process Audio
      echo "Processing audio..."
      # If MIDI, synthesize it. If Audio, copy it.
      if [[ "${cfg.soundFile}" =~ \.(mid|midi)$ ]]; then
        fluidsynth -ni "${cfg.soundFont}" "${cfg.soundFile}" -F audio.wav -r 48000 -g ${toString cfg.soundGain}
      else
        # FFmpeg cannot read directly from the nix store path sometimes depending on permission
        # safer to copy to build dir
        cp "${cfg.soundFile}" audio.wav
      fi

      # 2. Calculate Timings
      # Get total duration
      TOTAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 audio.wav)
      
      # Calculate fade start (Total - Fade Duration)
      FADE_START=$(echo "$TOTAL_DURATION - ${fadeDurationSecs}" | bc -l)
      echo "Duration: $TOTAL_DURATION. Fade start: $FADE_START"

      # 3. Render Video
      ffmpeg -y -i audio.wav \
        ${optionalString hasBackgroundVideo "-stream_loop -1 -i ${cfg.backgroundVideo}"} \
        ${optionalString (!hasBackgroundVideo) "-f lavfi -i color=c=black:s=${cfg.baseResolution}"} \
        ${optionalString hasLogo "${if isGif then "-ignore_loop 0" else ""} -i ${cfg.logoImage}"} \
        -filter_complex "\
          [1:v]scale=${cfg.baseResolution}:force_original_aspect_ratio=increase,crop=${cfg.baseResolution}[vbgscaled]; \
          [0:a]asplit=2[audio_viz][audio_final_raw]; \
          [audio_final_raw]afade=t=out:st=$FADE_START:d=${fadeDurationSecs}[audio_out]; \
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
    enable = mkEnableOption "Boot intro video system";
    
    # --- Video Options ---
    videoFile = mkOption { 
      type = types.nullOr types.path; 
      default = null; 
      description = "Path to a pre-rendered video. If set, generation is skipped."; 
    };
    baseResolution = mkOption { type = types.str; default = "1920x1080"; };
    titleText = mkOption { type = types.str; default = "Welcome to NixOS"; };
    bottomText = mkOption { type = types.str; default = "System Initializing..."; };
    logoImage = mkOption { type = types.nullOr types.path; default = null; };
    backgroundVideo = mkOption { type = types.nullOr types.path; default = null; };
    waveformOpacity = mkOption { type = types.float; default = 0.8; };
    fillMode = mkOption {
      type = types.enum [ "fill" "letterbox" "fit" ];
      default = "fill";
    };

    # --- Audio Options (New Standalone) ---
    soundFile = mkOption { 
      type = types.path; 
      description = "Path to audio file (wav/mp3/midi). Required for generation.";
    };
    soundGain = mkOption { 
      type = types.float; 
      default = 2.0; 
      description = "Volume gain for the audio."; 
    };
    soundFont = mkOption { 
      type = types.path; 
      default = "${pkgs.fluid-soundfont-gm}/share/soundfonts/FluidR3_GM.sf2";
      description = "Path to SF2 soundfont (only used if soundFile is MIDI).";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.mpv ];

    # The service that plays the video on boot
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

    # Prevent SDDM from clearing the screen immediately
    services.displayManager.sddm.extraConfig = optionalString (config.services.displayManager.sddm.enable) ''
      [General]
      InputMethod=
    '';
  };
}
