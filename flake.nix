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

        # Patch hnix so that select-on-application keeps its parentheses
        # (see issue #20; upstream hnix unfixed in 0.17.0).
        hpkgs = pkgs.haskellPackages.extend (
          self: super: {
            hnix = super.hnix.overrideAttrs (old: {
              doCheck = false;
              doHaddock = false;
              patches = (old.patches or [ ]) ++ [ ./patches/hnix-nselect-parens.patch ];
            });
          }
        );

        nix-ast-dev = hpkgs.callCabal2nix "nix-ast" src { };

        nix-ast-release = pkgs.haskell.lib.justStaticExecutables (
          nix-ast-dev.overrideAttrs (old: {
            doCheck = false;
            configureFlags = (old.configureFlags or [ ]) ++ [
              "--ghc-option=-O2"
              "--ghc-option=-threaded"
              "--ghc-option=-rtsopts"
              "--ghc-option=-with-rtsopts=-N"
            ];
            postInstall = (old.postInstall or "") + ''
              remove-references-to -t ${hpkgs.hnix} $out/bin/nix-ast
            '';
          })
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
            hpkgs.haskell-language-server
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
