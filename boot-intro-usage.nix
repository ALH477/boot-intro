# ════════════════════════════════════════════════════════════════════════════
# Boot Intro Integration Example
# Add to your main configuration.nix
# ════════════════════════════════════════════════════════════════════════════

{ config, pkgs, lib, inputs, nixpkgs-unstable, ... }:

{
  imports = [
    ./modules/audio.nix
    ./modules/boot-intro.nix  # ← Add this import
  ];

  # ... rest of your config ...

  # ──────────────────────────────────────────────────────────────────────────
  # DeMoD Boot Intro
  # ──────────────────────────────────────────────────────────────────────────
  services.boot-intro = {
    enable = true;

    # Theme selection — pick your DeMoD palette
    # Options: classic, amber, cyan, magenta, red, white, oligarchy, archibald
    theme = "oligarchy";

    # Branding
    titleText = "Oligarchy";
    bottomText = "Design ≠ Marketing";

    # Optional: Your logo (PNG or animated GIF)
    # logoImage = ./assets/demod-logo.png;
    # logoScale = 0.4;

    # Audio source — MIDI gets synthesized, audio files normalized
    soundFile = ./assets/boot-chime.mid;
    # Or use a wav/mp3/flac:
    # soundFile = ./assets/boot-intro.wav;

    # Optional: Background video (loops behind waveform)
    # backgroundVideo = ./assets/grid-animation.mp4;

    # Visual tuning
    resolution = "2560x1600";  # Match your Framework 16 display
    waveformOpacity = 0.7;
    fadeDuration = 2.0;
  };

  # ... rest of your config ...
}
