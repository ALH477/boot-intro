## Boot Intro for NixOS

### Copyright (c) 2026, DeMoD LLC. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 3. Neither the name of DeMoD LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE of THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

This NixOS module provides a high-performance, retro-futuristic boot animation system designed to bridge the transition between system initialization and the login manager. It utilizes a sophisticated FFmpeg filter pipeline to generate audio-reactive waveforms with CRT scanlines, lens curvature, and bloom effects rendered at a native 16:10 2K resolution. The system is engineered for maximum compatibility by executing via a dedicated systemd service that targets the raw framebuffer, ensuring seamless operation across both X11 and Wayland environments.

Installation is handled by importing the module into your NixOS configuration and enabling the service. The module automatically handles complex media tasks including MIDI synthesis via FluidSynth and dynamic video scaling. Users can customize the visual output through options for title text, branding logos, background video overlays, and waveform opacity. The rendering engine calculates precise synchronization for audio and video fades to ensure a professional handoff to the display manager.

The source code and technical documentation are maintained by alh477 on GitHub. For advanced implementation details or to report issues regarding hardware-accelerated decoding via MPV, please visit the official repository.
