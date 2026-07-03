{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      src = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [
          ./CHANGELOG.md
          ./LICENSE
          ./app
          ./nix-ast.cabal
          ./src
          ./test
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        hpkgs = pkgs.haskellPackages;
        hlib = pkgs.haskell.lib;
        nix-ast-dev = hpkgs.callCabal2nix "nix-ast" src { };
        nix-ast-release = hlib.justStaticExecutables (
          hlib.appendConfigureFlags nix-ast-dev [
            "--ghc-option=-O2"
            "--ghc-option=-threaded"
            "--ghc-option=-rtsopts"
            "--ghc-option=-with-rtsopts=-N"
          ]
        );
      in
      {
        packages = {
          default = nix-ast-release;
          nix-ast = nix-ast-release;
        };

        checks = {
          inherit nix-ast-dev;
          tests = pkgs.runCommand "nix-ast-tests" {
            requiredTestResults = import ./nix/tests.nix {
              inherit pkgs;
              inherit (self) lib;
            };
          } "echo all tests passed > $out";
        };

        devShells.default = hpkgs.shellFor {
          packages = p: [ nix-ast-dev ];
          buildInputs = with pkgs; [
            cabal-install
            fourmolu
            ghcid
            hlint
            hpkgs.cabal-fmt
          ];
        };
      }
    )
    // {
      lib = import ./nix/lib {
        inherit (nixpkgs) lib;
        inherit (self) packages;
      };
    };
}
