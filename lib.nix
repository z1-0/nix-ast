{
  pkgs ? import <nixpkgs> {},
  packages,
}: let
  inherit (pkgs) runCommand stdenv;
  inherit (stdenv.hostPlatform) system;
in {
  # Parse a .nix file into a JSON AST value.
  # parse :: Path -> attrset
  parse = src: let
    json = runCommand "nix-ast-parse" {
      nativeBuildInputs = [packages.${system}.nix-ast];
    } "nix-ast parse -f ${src} > $out";
  in
    builtins.fromJSON (builtins.readFile json);

  # Generate a .nix file from a JSON AST value.
  # gen :: attrset -> Path
  gen = ast:
    runCommand "nix-ast-gen" {
      nativeBuildInputs = [packages.${system}.nix-ast];
    } "nix-ast gen -f ${builtins.toFile "input.json" (builtins.toJSON ast)} > $out";
}
