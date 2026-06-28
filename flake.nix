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
        nix-ast = hpkgs.callCabal2nix "nix-ast" src { };
      in
      {
        packages = {
          default = nix-ast;
          inherit nix-ast;
        };

        checks.tests = pkgs.runCommand "nix-ast-tests" {
          requiredTestResults = import ./nix/tests.nix {
            inherit pkgs;
            inherit (self) lib;
          };
        } "echo all tests passed > $out";

        devShells.default = hpkgs.shellFor {
          packages = p: [ nix-ast ];
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
