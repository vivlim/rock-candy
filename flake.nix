{
  description = "Some luarocks packaged in a flake outside of nixpkgs";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    luarocks-nix = {
      url = "github:nix-community/luarocks-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, luarocks-nix, ... }:
    let
      overlays = [ (final: prev: (import ./overlay.nix {pkgs = prev; nixpkgsFlake = nixpkgs; inherit luarocks-nix;})) ];
      overlayModule =
        ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; });
    in {
      devShells = let
        devShellSupportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        devShellForEachSupportedSystem = f: nixpkgs.lib.genAttrs devShellSupportedSystems (system: f {
          pkgs = import nixpkgs { inherit system; inherit overlays; };
          inherit system;
        });
      in devShellForEachSupportedSystem ({ pkgs, system }: {
        default = pkgs.mkShell {
          packages = [ pkgs.nil pkgs.nixfmt ];
        };
      });

      packages = let
        pkgSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        packagesForEachSystem = f: nixpkgs.lib.genAttrs pkgSystems (system: f {
          pkgs = import nixpkgs { inherit system; inherit overlays; };

        });
      in packagesForEachSystem ({ pkgs }: {
        croissant = pkgs.croissant-script;
      } // (import ./generator.nix {inherit pkgs; inherit luarocks-nix;}));

      # Export useful functions outside of the flake.
      lib = (import ./lib { lib = nixpkgs.lib; });
    };
}
