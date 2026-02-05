{
  description = "NixOS boot intro video generator with audio visualization";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosModules = {
      default = import ./module.nix;
      boot-intro = import ./module.nix;
    };

    # Development shell for testing
    devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            ffmpeg-full
            fluidsynth
            mpv
            soundfont-fluid
          ];
        };
      }
    );

    # Expose the video generator for standalone builds
    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Example: nix build .#example-video
        example-video = pkgs.callPackage ./example.nix { };
      }
    );
  };
}
