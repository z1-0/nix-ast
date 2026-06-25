{
  pkgs ? import <nixpkgs> {},
  packages,
}: let
  inherit (pkgs) runCommand stdenv;
  inherit (stdenv.hostPlatform) system;
in {
  # Generate a .nix file from a JSON AST value.
  # render :: attrset -> Path
  render = ast:
    runCommand "nix-ast-render" {
      nativeBuildInputs = [packages.${system}.nix-ast];
    } "nix-ast render -f ${builtins.toFile "input.json" (builtins.toJSON ast)} > $out";

  # Parse a .nix file into a JSON AST value.
  # parse :: Path -> attrset
  parse = src: let
    json = runCommand "nix-ast-parse" {
      nativeBuildInputs = [packages.${system}.nix-ast];
    } "nix-ast parse -f ${src} > $out";
  in
    builtins.fromJSON (builtins.readFile json);

  match = import ./match.nix;
  syntax = import ./syntax.nix;
  traversal = import ./traversal.nix;
  types = import ./types.nix;
}
