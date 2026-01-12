## Boot Intro for NixOS

### Copyright (c) 2026, DeMoD LLC. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 3. Neither the name of DeMoD LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

This NixOS module provides a high-performance, retro-futuristic boot animation system designed to bridge the transition between system initialization and the login manager. It utilizes a sophisticated FFmpeg filter pipeline to generate audio-reactive waveforms with CRT scanlines, lens curvature, and bloom effects rendered at a native 16:10 2K resolution. The system is engineered for maximum compatibility by executing via a dedicated systemd service that targets the raw framebuffer, ensuring seamless operation across both X11 and Wayland environments.

Installation is handled by importing the module into your NixOS configuration and enabling the service. The module automatically handles complex media tasks including MIDI synthesis via FluidSynth and dynamic video scaling. Users can customize the visual output through options for title text, branding logos, background video overlays, and waveform opacity. The rendering engine calculates precise synchronization for audio and video fades to ensure a professional handoff to the display manager.

---

## Implementation Guide

Integration begins by adding the repository to your flake inputs and including the module in your system configuration. Within your NixOS configuration files, you must enable the service by setting `services.boot-intro.enable = true`. A valid audio source is required, which is typically provided by configuring `services.boot-sound.soundFile` with a path to a high-quality WAV, MP3, or MIDI file. If a MIDI file is selected, the module automatically utilizes the FluidR3_GM soundfont for synthesis unless an alternative is specified.

Visual customization is achieved by defining the `logoImage` and `backgroundVideo` paths. For the best aesthetic results at the default 2560x1600 resolution, logos should be provided as transparent PNG files or animated GIFs. If a background video is supplied, it is recommended to reduce `waveformOpacity` to approximately 0.4 to ensure the reactive elements complement rather than obscure the background footage. The systemd service is configured to conflict with the standard Getty on TTY1 to prevent text bleed during playback, while the `StandardOutput=tty` directive ensures the MPV instance maintains priority over the physical display.

Monitoring the build process is essential as the first generation of the video involves a slow-preset software encode to ensure high visual fidelity. You can verify the generated output by inspecting the result in the Nix store or by running the player manually from the development shell. For troubleshooting hardware acceleration issues, users should verify that their kernel supports the appropriate DRM/KMS drivers for their specific GPU, as the auto-detection logic in MPV relies on these interfaces for zero-copy video playback.

The source code and technical documentation are maintained by alh477 on GitHub. For advanced implementation details or to report issues regarding hardware-accelerated decoding via MPV, please visit the official repository.
