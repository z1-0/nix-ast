{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      haskellPkgs = pkgs.haskellPackages;
      nix-ast = haskellPkgs.callCabal2nix "nix-ast" ./. {};
    in {
      packages = {
        default = nix-ast;
        inherit nix-ast;
      };
      devShells.default = haskellPkgs.shellFor {
        packages = p: [nix-ast];
        buildInputs = with pkgs; [
          cabal-install
          fourmolu
          ghcid
          haskellPkgs.hlint
          haskellPkgs.cabal-fmt
        ];
      };
    })
    // {
      lib = import ./nix/lib {inherit (self) packages;};
    };
}
