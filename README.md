# boot-intro

A NixOS module for generating and displaying branded boot intro videos with real-time audio visualization. Part of the DeMoD (Design ≠ Marketing) ecosystem.

![License](https://img.shields.io/badge/license-BSD--3--Clause-blue)
![NixOS](https://img.shields.io/badge/NixOS-24.11%2B-5277C3?logo=nixos)

## Overview

boot-intro generates a video at build time featuring:

- Symmetric audio waveform visualization with bloom effects
- CRT-style scanlines and barrel distortion
- Configurable color palettes (8 built-in themes)
- MIDI synthesis or audio file support
- Optional logo overlay and background video

The video plays after Plymouth exits and before your display manager starts, providing a seamless branded boot experience.

## Installation

### Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    boot-intro.url = "github:demod-llc/boot-intro";
  };

  outputs = { self, nixpkgs, boot-intro, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        boot-intro.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Traditional

Clone the repository and import the module:

```nix
{ config, pkgs, ... }:

{
  imports = [
    /path/to/boot-intro/module.nix
  ];
}
```

## Configuration

### Minimal Example

```nix
services.boot-intro = {
  enable = true;
  theme = "classic";
  soundFile = ./assets/chime.mid;
};
```

### Full Example

```nix
services.boot-intro = {
  enable = true;
  
  # Visual theme
  theme = "oligarchy";
  resolution = "2560x1600";
  
  # Branding
  titleText = "Oligarchy";
  bottomText = "Initializing...";
  logoImage = ./assets/logo.png;
  logoScale = 0.4;
  
  # Background (optional — solid color from theme if unset)
  backgroundVideo = ./assets/grid.mp4;
  
  # Audio source
  soundFile = ./assets/boot.wav;
  
  # Tuning
  waveformOpacity = 0.75;
  fadeDuration = 2.0;
  fillMode = "fill";
};
```

## Options Reference

### Core

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the boot intro service |
| `videoFile` | path | `null` | Pre-rendered video (skips generation) |
| `theme` | enum | `"classic"` | Color palette selection |

### Visual

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resolution` | string | `"1920x1080"` | Output resolution |
| `titleText` | string | `"DeMoD"` | Top title text |
| `bottomText` | string | `"Design ≠ Marketing"` | Bottom subtitle |
| `logoImage` | path | `null` | Center logo (PNG/GIF) |
| `logoScale` | float | `0.35` | Logo size relative to height |
| `backgroundVideo` | path | `null` | Looping background video |
| `waveformOpacity` | float | `0.75` | Visualization opacity (0.0–1.0) |
| `fadeDuration` | float | `1.5` | Fade-out duration in seconds |
| `fillMode` | enum | `"fill"` | `"fill"` or `"letterbox"` |

### Text Layout

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `titleSize` | int | `16` | Title font size (height ÷ N) |
| `titleY` | int | `8` | Title Y position (height ÷ N) |
| `bottomSize` | int | `28` | Bottom text font size |
| `bottomY` | int | `10` | Bottom text Y offset |

### Audio

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `soundFile` | path | `null` | Audio source (wav/mp3/flac/midi) |
| `soundGain` | float | `2.0` | MIDI synthesis gain |
| `soundFont` | path | FluidR3_GM | SF2 soundfont for MIDI |

### Service

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `timeout` | int | `30` | Max playback time (seconds) |

## Themes

| Name | Primary | Description |
|------|---------|-------------|
| `classic` | `#00FF88` | Phosphor green — original DeMoD |
| `amber` | `#FFB000` | Warm CRT terminal |
| `cyan` | `#00FFFF` | Cool tech aesthetic |
| `magenta` | `#FF00FF` | Synthwave influence |
| `red` | `#FF3333` | Warning/alert mode |
| `white` | `#FFFFFF` | High contrast accessibility |
| `oligarchy` | `#7AA2F7` | Tokyo Night-inspired |
| `archibald` | `#A6E3A1` | Catppuccin green |

## How It Works

1. **Build time**: The module generates an MP4 using FFmpeg with the configured audio, visuals, and theme. MIDI files are synthesized via FluidSynth.

2. **Boot time**: A systemd oneshot service plays the video on TTY1 using mpv after Plymouth exits and before the display manager starts.

3. **Fallback**: If GPU initialization fails, mpv falls back to DRM output. Playback errors don't block boot.

### Service Ordering

```
plymouth-quit-wait.service
         ↓
boot-intro-player.service  ←  conflicts with getty@tty1
         ↓
display-manager.service
```

## Requirements

- NixOS 24.11 or later
- GPU with working DRM/KMS (AMD, Intel, or NVIDIA with modesetting)
- Audio output (optional but recommended)

### Build Dependencies (handled by Nix)

- ffmpeg-full
- fluidsynth (for MIDI)
- mpv
- dejavu_fonts
- soundfont-fluid

## Troubleshooting

### Video doesn't play

Check the journal:

```bash
journalctl -u boot-intro-player.service
```

Common issues:
- GPU driver not loaded early enough — add your GPU module to `boot.initrd.kernelModules`
- Audio device not ready — the video will still play without sound

### Black screen during intro

Ensure your display manager isn't racing the intro:

```nix
# SDDM users — this is set automatically by the module
services.displayManager.sddm.settings.General.InputMethod = "";
```

### Video too long/short

The video duration matches your audio file. Adjust `fadeDuration` if the ending feels abrupt.

### Wrong resolution

Set `resolution` to match your display:

```nix
services.boot-intro.resolution = "2560x1600";  # Framework 16
services.boot-intro.resolution = "3840x2160";  # 4K
```

## Development

### Testing the generated video

Build and preview without rebooting:

```bash
nix-build -E 'with import <nixpkgs> {}; callPackage ./test.nix {}'
mpv result
```

### Custom themes

Define additional palettes in the `demodPalettes` attrset:

```nix
myTheme = {
  primary = "#FF6600";
  secondary = "#CC5200";
  accent = "#FF9944";
  background = "#0A0500";
  text = "#FF6600";
  waveform = "#FF6600";
};
```

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.

## Credits

Developed by [DeMoD LLC](https://demod.ltd) as part of the Oligarchy NixOS distribution.

---

*Design ≠ Marketing*
