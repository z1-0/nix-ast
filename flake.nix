{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forEachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

    ghcVersion = "ghc910";

    forHaskellPkgs = f: pkgs: f pkgs pkgs.haskell.packages.${ghcVersion};
  in {
    lib = import ./lib.nix {inherit (self) packages;};

    libWith = pkgs:
      import ./lib.nix {
        inherit pkgs;
        inherit (self) packages;
      };

    packages = forEachSystem (
      forHaskellPkgs (
        pkgs: haskellPkgs: let
          nix-ast = haskellPkgs.callCabal2nix "nix-ast" ./. {};
        in {
          default = nix-ast;
          inherit nix-ast;
        }
      )
    );

    devShells = forEachSystem (
      forHaskellPkgs (
        pkgs: haskellPkgs: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              haskell.compiler.${ghcVersion}
              haskellPkgs.cabal-fmt
              haskellPkgs.cabal-install
              haskellPkgs.fourmolu
              haskellPkgs.haskell-language-server
              haskellPkgs.hlint
              pkg-config
            ];

            buildInputs = with pkgs; [
              libsodium
              zlib
            ];
          };
        }
      )
    );
  };
}
