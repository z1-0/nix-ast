{
  pkgs ? import <nixpkgs> {},
  packages,
}: let
  inherit (pkgs) runCommand stdenv;
  inherit (stdenv.hostPlatform) system;
  lib = pkgs.lib;

  match = import ./match.nix;
  syntax = import ./syntax.nix;
  traversal = import ./traversal.nix;
  types = import ./types.nix;
in {
  inherit syntax match traversal types;

  # Convert an AST value to a .nix file.
  # render :: AST -> Path
  render = ast:
    runCommand "nix-ast-render" {
      nativeBuildInputs = [packages.${system}.nix-ast];
    } "nix-ast render -f ${builtins.toFile "ast.json" (builtins.toJSON ast)} > $out";

  # Parse a .nix file into an AST value.
  # parse :: Path -> AST
  parse = src: let
    json = runCommand "nix-ast-parse" {
      nativeBuildInputs = [packages.${system}.nix-ast];
    } "nix-ast parse -f ${src} > $out";
  in
    builtins.fromJSON (builtins.readFile json);

  # Convert any Nix value to its AST, recursing into attrsets and lists.
  # Throws on functions, derivations, and unsupported types.
  # toAST :: Any -> AST
  toAST = value: let
    go = v:
      if builtins.isBool v
      then syntax.mkBool v
      else if builtins.isInt v
      then syntax.mkInt v
      else if builtins.isFloat v
      then syntax.mkFloat v
      else if builtins.isNull v
      then syntax.mkNull
      else if builtins.isString v
      then syntax.mkDoubleQuoted [(syntax.mkPlain v)]
      else if builtins.isPath v
      then syntax.mkLiteralPath (toString v)
      else if builtins.isList v
      then syntax.mkList (map go v)
      else if builtins.isFunction v
      then throw "toAST: cannot convert function to AST"
      else if builtins.isAttrs v
      then
        if v ? type && v.type == "derivation"
        then throw "toAST: cannot convert derivation to AST"
        else
          syntax.mkSet false (lib.mapAttrsToList (
              name: val:
                syntax.mkNamedVar [(syntax.mkStaticKey name)] (go val)
            )
            v)
      else throw "toAST: unsupported Nix type";
  in
    go value;
}
