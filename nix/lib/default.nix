{ lib, packages }:

let
  match = import ./match.nix;
  syntax = import ./syntax.nix;
  traversal = import ./traversal.nix;

  nix-ast-cli = pkgs: packages.${pkgs.stdenv.hostPlatform.system}.nix-ast;

  # Evaluate multiple ASTs in a single IFD derivation.
  # NOTE: This is an IFD (Import From Derivation) function.
  evalMany =
    pkgs: asts:
    let
      json = pkgs.runCommand "nix-ast-eval" {
        nativeBuildInputs = [ (nix-ast-cli pkgs) ];
      } ''
        nix-ast eval-batch -f ${builtins.toFile "asts.json" (builtins.toJSON asts)} > $out
      '';
    in
    builtins.fromJSON (builtins.readFile json);
in

{
  inherit
    # pseudo pattern matching over node tag
    match
    # type-checked constructors and predicates
    syntax
    # traversal and transformation
    traversal
    # batch evaluate multiple ASTs via IFD
    evalMany
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

  # Evaluate an AST using hnix and return the result as JSON.
  # NOTE: This is an IFD (Import From Derivation) function.
  # eval :: pkgs -> AST -> Any
  eval =
    pkgs: ast:
    builtins.head (evalMany pkgs [ ast ]);

  # Convert an AST back to a Nix value.
  # This is the inverse of `toAST` for all values it supports.
  # Strings with interpolation work when the interpolated expression is a Str node or plain text.
  # NOTE: Paths are returned as strings since Nix cannot dynamically construct a path value.
  # fromAST :: AST -> a
  fromAST =
    ast:
    let
      go = node:
        match node {
          Constant = { contents, ... }:
            match contents {
              Int = { contents, ... }: contents;
              Float = { contents, ... }: contents;
              Bool = { contents, ... }: contents;
              Null = _: null;
              Uri = { contents, ... }: contents;
              _ = _: throw "fromAST: unsupported atom type '${contents.tag}'";
            };
          Str = { contents, ... }:
            match contents {
              DoubleQuoted = { contents, ... }:
                builtins.concatStringsSep "" (map textFromPart contents);
              Indented = { parts, ... }:
                builtins.concatStringsSep "" (map textFromPart parts);
            };
          EnvPath = { contents, ... }: contents;
          LiteralPath = { contents, ... }: contents;
          List = { contents, ... }: map go contents;
          Set = { recursive, bindings, ... }:
            if recursive then
              throw "fromAST: cannot convert recursive set to Nix value"
            else
              lib.listToAttrs (lib.concatMap (binding: match binding {
                NamedVar = { attrPath, value, ... }:
                  [{ name = keyFromKeyName (builtins.head attrPath); value = go value; }];
                Inherit = { scope, names, ... }:
                  if scope == null then
                    throw "fromAST: plain inherit (without scope) is not supported"
                  else
                    let scopeVal = go scope;
                    in map (name: { inherit name; value = scopeVal.${name}; }) names;
              }) bindings);
          _ = _: throw "fromAST: unsupported AST node '${node.tag}'";
        };

      textFromPart = part: match part {
        Plain = { contents, ... }:
          if builtins.isString contents then contents
          else go contents;
        Antiquoted = { contents, ... }:
          if builtins.isString contents then contents
          else if syntax.isStr contents then go contents
          else throw "fromAST: string interpolation only supports Str nodes or plain text";
        EscapedNewline = _: "";
      };

      keyFromKeyName = keyName: match keyName {
        StaticKey = { contents, ... }: contents;
        DynamicKey = { contents, ... }: textFromPart contents;
      };
    in
    go ast;

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
