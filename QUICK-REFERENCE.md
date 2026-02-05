# Boot Intro Quick Reference - DSP Edition

## 🎚️ For Audio Production Workstations

### Scenario: Focusrite Scarlett Interface
```nix
services.boot-intro = {
  enable = true;
  theme = "archibald";
  soundFile = ./studio-intro.flac;
  
  # Auto-detects Scarlett as priority device
  initialVolume = 70;  # Safe level for monitors
  debugAudio = true;   # Verify detection once
};
```

### Scenario: RME Fireface
```nix
services.boot-intro = {
  enable = true;
  theme = "archibald";
  soundFile = ./rme-intro.wav;
  
  # Will find RME first (USB priority)
  audioChannels = "stereo";
  initialVolume = 65;  # Conservative for studio monitors
};
```

### Scenario: Multiple Interfaces (Force Specific)
```nix
services.boot-intro = {
  enable = true;
  theme = "classic";
  soundFile = ./boot.mp3;
  
  # Force main interface when you have monitoring interface too
  audioDevice = "hw:2,0";  # Check with: aplay -l
  initialVolume = 75;
};
```

### Scenario: JACK/PipeWire Routing
Note: Boot intro uses ALSA directly (before JACK/PipeWire starts).
Choose your main hardware output:
```nix
services.boot-intro = {
  enable = true;
  soundFile = ./intro.wav;
  
  # Use physical output, not JACK virtual device
  # Auto-detection handles this correctly
  debugAudio = true;  # Check it's not selecting loopback
};
```

---

## 🚀 Speed Optimization Presets

### Fastest Boot (SSD + Integrated Audio)
```nix
services.boot-intro = {
  enable = true;
  startEarly = true;
  startupDelay = 0.1;
  fadeOnSystemd = true;
  fadeDuration = 0.8;
  resolution = "1920x1080";
};
```

### Fastest Boot (USB Audio)
```nix
services.boot-intro = {
  enable = true;
  startEarly = true;
  startupDelay = 0.3;  # USB needs enumeration time
  fadeOnSystemd = true;
  fadeDuration = 1.0;
  initialVolume = null;  # Skip volume setting
};
```

### Reliable Boot (Any Hardware)
```nix
services.boot-intro = {
  enable = true;
  startEarly = false;      # Wait for sound.target
  startupDelay = 0.2;
  fadeOnSystemd = true;
  fadeDuration = 1.5;
};
```

---

## 🎨 Theme Selection Guide

```nix
# For studio environments (neutral, professional)
theme = "archibald";  # Green/cyan production vibe
theme = "white";      # High contrast, clean

# For live performance systems
theme = "cyan";       # Cool tech aesthetic
theme = "magenta";    # Synthwave energy

# For mixing/mastering stations
theme = "classic";    # Retro console feel
theme = "amber";      # Warm CRT monitor vibe

# For corporate/client-facing
theme = "oligarchy";  # Modern, polished
```

---

## 🐛 Debug Checklist

### Audio Not Working?
```bash
# 1. Check service status
systemctl status boot-intro-player.service

# 2. View full log
journalctl -u boot-intro-player.service -b

# 3. Test your audio file manually
mpv --ao=alsa --audio-device=alsa/default your-sound.mp3

# 4. List detected devices
aplay -l
cat /proc/asound/cards
```

### Enable verbose debugging:
```nix
services.boot-intro.debugAudio = true;
# Rebuild and check: journalctl -u boot-intro-player.service -b
```

---

## 📝 Common Patterns

### Pattern: "I have HDMI monitors and a USB interface"
```nix
# Auto-detect will prefer USB interface (professional hardware priority)
# Just enable and verify:
services.boot-intro = {
  enable = true;
  debugAudio = true;  # Check it found USB, not HDMI
};
```

### Pattern: "My interface is on USB hub, slow to enumerate"
```nix
services.boot-intro = {
  enable = true;
  startupDelay = 0.5;  # Give hub time
  fadeOnSystemd = true;
};
```

### Pattern: "I switch between headphones and monitors"
```nix
# Boot intro uses hardware device directly
# ALSA routing happens after boot
# Use default ALSA device selection:
services.boot-intro.audioDevice = "";  # Auto-detect
```

### Pattern: "I need silent boot sometimes"
```nix
# Add this to your configuration:
boot.kernelParams = [ "quiet" ];
services.boot-intro.volume = 0;  # Or remove enable = true;
```

---

## 🔧 Integration with Other Services

### With PipeWire
```nix
# Boot intro finishes before PipeWire starts - no conflict
services.pipewire.enable = true;
services.boot-intro.enable = true;
# Both work fine!
```

### With JACK
```nix
# Same - ALSA direct access during boot, JACK takes over after
services.jack.jackd.enable = true;
services.boot-intro.enable = true;
```

### With Plymouth (Boot Splash)
```nix
boot.plymouth.enable = true;
services.boot-intro = {
  enable = true;
  # Will start after Plymouth quits
  # Seamless transition!
};
```

---

## 💡 Pro Tips

1. **Pre-render videos** in your desired resolution to save rebuild time
2. **Use FLAC** for audio source if you're particular about quality
3. **Set initialVolume** to avoid startling loud monitors
4. **Enable debugAudio** once to verify detection, then disable
5. **Keep intro under 5 seconds** for best user experience
6. **Test with `nixos-rebuild test`** before committing changes

---

## 📊 Decision Matrix

| Your Setup | startEarly | startupDelay | fadeOnSystemd |
|-----------|-----------|--------------|---------------|
| Fast SSD, integrated audio | true | 0.1s | true |
| Fast SSD, USB interface | true | 0.3s | true |
| HDD, any audio | false | 0.2s | true |
| HDMI audio | false | 0.3s | true |
| Multiple GPUs | false | 0.5s | true |
| Reliability > speed | false | 0.3s | true |

---

## 🎯 One-Liner Configs

```nix
# Absolute minimum (auto-everything)
services.boot-intro = { enable = true; soundFile = ./boot.mp3; };

# Pro audio (Focusrite/RME auto-detect)
services.boot-intro = { enable = true; soundFile = ./studio.flac; initialVolume = 70; };

# Maximum speed
services.boot-intro = { enable = true; soundFile = ./fast.wav; startEarly = true; startupDelay = 0.1; fadeOnSystemd = true; };

# Debug mode
services.boot-intro = { enable = true; soundFile = ./test.mp3; debugAudio = true; volume = 50; };

# Manual device
services.boot-intro = { enable = true; soundFile = ./boot.mp3; audioDevice = "hw:1,0"; };
```

---

**Design ≠ Marketing** | **DeMoD Boot Intro System** | v2.0
