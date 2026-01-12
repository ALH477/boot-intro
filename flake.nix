{
  description = "Retro-futuristic boot animation module for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    # Export the module so it can be imported by other configurations
    nixosModules.default = import ./boot-intro.nix;

    # Optional: A development shell for testing the FFmpeg commands manually
    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.mkShell {
      buildInputs = with pkgs; [ ffmpeg-full fluidsynth mpv bc ];
    };
  };
}
