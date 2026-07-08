{ lib, packages }:

let
  match = import ./match.nix;
  syntax = import ./syntax.nix;
  traversal = import ./traversal.nix;

  nix-ast-cli = pkgs: packages.${pkgs.stdenv.hostPlatform.system}.nix-ast;
in

{
  inherit
    # pseudo pattern matching over node tag
    match
    # type-checked constructors and predicates
    syntax
    # traversal and transformation
    traversal
    ;

  # Convert an AST value to a .nix file.
  # NOTE: This is an IFD (Import From Derivation) function.
  # render :: pkgs -> AST -> Path
  render =
    pkgs: ast:
    pkgs.runCommand "nix-ast-render" {
      nativeBuildInputs = [ (nix-ast-cli pkgs) ];
    } "nix-ast render -f ${builtins.toFile "ast.json" (builtins.toJSON ast)} > $out";

  # Parse a .nix file into an AST value.
  # NOTE: This is an IFD (Import From Derivation) function.
  # parse :: pkgs -> Path -> AST
  parse =
    pkgs: src:
    let
      json = pkgs.runCommand "nix-ast-parse" {
        nativeBuildInputs = [ (nix-ast-cli pkgs) ];
      } "nix-ast parse -f ${src} > $out";
    in
    builtins.fromJSON (builtins.readFile json);

  # Convert any Nix value to its AST, recursing into attrsets and lists.
  # Functions and derivations are not supported and will raise an error.
  # toAST :: a -> AST
  toAST =
    value:
    let
      go =
        v:
        with builtins;
        if isBool v then syntax.mkBool v
        else if isInt v then syntax.mkInt v
        else if isFloat v then syntax.mkFloat v
        else if isNull v then syntax.mkNull
        else if isString v then syntax.mkStr (syntax.mkDoubleQuoted [ (syntax.mkPlain v) ])
        else if isPath v then syntax.mkLiteralPath (toString v)
        else if isList v then syntax.mkList (map go v)
        else if isFunction v then throw "toAST: cannot convert function to AST"
        else if isAttrs v then
          if v ? type && v.type == "derivation" then
            throw "toAST: cannot convert derivation to AST"
          else
            syntax.mkSet false (
              lib.mapAttrsToList (name: val: syntax.mkNamedVar [ (syntax.mkStaticKey name) ] (go val)) v
            )
        else
          throw "toAST: unsupported Nix type";
    in
    go value;
}
