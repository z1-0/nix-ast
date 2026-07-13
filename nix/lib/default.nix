{ lib, packages }:

let
  match = import ./match.nix;
  syntax = import ./syntax.nix;
  traversal = import ./traversal;

  nix-ast-cli = pkgs: packages.${pkgs.stdenv.hostPlatform.system}.nix-ast;
in

{
  inherit match syntax traversal;

  # Evaluate ASTs to Nix values.
  # Only JSON-serializable values are supported; functions and derivations error.
  # NOTE: IFD (Import From Derivation).
  # eval :: pkgs -> [AST] -> [a]
  eval =
    pkgs: asts:
    let
      json = pkgs.runCommand "nix-ast-eval" {
        nativeBuildInputs = [ (nix-ast-cli pkgs) ];
      } "nix-ast eval < ${pkgs.writeText "asts.json" (builtins.toJSON asts)} > $out";
    in
    builtins.fromJSON (builtins.readFile json);

  # Parse .nix files into AST values.
  # NOTE: IFD (Import From Derivation).
  # parse :: pkgs -> [Path] -> [AST]
  parse =
    pkgs: paths:
    let
      json = pkgs.runCommand "nix-ast-parse" {
        nativeBuildInputs = [ (nix-ast-cli pkgs) ];
      } "nix-ast parse < ${pkgs.writeText "paths.json" (builtins.toJSON paths)} > $out";
    in
    builtins.fromJSON (builtins.readFile json);

  # Render ASTs to importable .nix files (named <n>.nix by index).
  # NOTE: IFD (Import From Derivation).
  # render :: pkgs -> [AST] -> [Path]
  render =
    pkgs: asts:
    let
      dir = pkgs.runCommand "nix-ast-render" { nativeBuildInputs = [ (nix-ast-cli pkgs) ]; } ''
        mkdir -p $out
        nix-ast render --out-dir $out < ${pkgs.writeText "serialize.json" (builtins.toJSON asts)}
      '';
    in
    lib.imap0 (i: _: "${dir}/${toString i}.nix") asts;

  # Convert a Nix value to its AST (recurses into attrsets and lists).
  # Functions and derivations will raise an error.
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
        else if isFunction v then
          throw "toAST: cannot convert function to AST"
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

  # Convert an AST to a Nix value (inverse of toAST).
  # A pure evaluation function — no IFD, runs entirely in Nix.
  # Paths are returned as strings; interpolation only supports Str nodes or plain text.
  # fromAST :: AST -> a
  fromAST =
    ast:
    let
      go =
        node:
        match node {
          Constant = { contents, ... }:
            match contents {
              Int = { contents, ... }: contents;
              Float = { contents, ... }: contents;
              Bool = { contents, ... }: contents;
              Uri = { contents, ... }: contents;
              Null = _: null;
              _ = _: throw "fromAST: unsupported atom type '${contents.tag}'";
            };
          Str = { contents, ... }:
            match contents {
              DoubleQuoted = { contents, ... }: builtins.concatStringsSep "" (map textFromPart contents);
              Indented = { parts, ... }: builtins.concatStringsSep "" (map textFromPart parts);
            };
          EnvPath = { contents, ... }: contents;
          LiteralPath = { contents, ... }: contents;
          List = { contents, ... }: map go contents;
          Set = { recursive, bindings, ... }:
            if recursive then
              throw "fromAST: cannot convert recursive set to Nix value"
            else
              lib.listToAttrs (
                lib.concatMap (
                  binding:
                  match binding {
                    NamedVar = { attrPath, value, ... }:
                      [
                        { name = keyFromKeyName (builtins.head attrPath); value = go value; }
                      ];
                    Inherit = { scope, names, ... }:
                      if scope == null then
                        throw "fromAST: plain inherit (without scope) is not supported"
                      else
                        let
                          scopeVal = go scope;
                        in
                        map (name: {
                          inherit name;
                          value = scopeVal.${name};
                        }) names;
                  }
                ) bindings
              );
          _ = _: throw "fromAST: unsupported AST node '${node.tag}'";
        };

      textFromPart = part:
        match part {
          Plain = { contents, ... }: if builtins.isString contents then contents else go contents;
          Antiquoted = { contents, ... }:
            if builtins.isString contents then
              contents
            else if syntax.isStr contents then
              go contents
            else
              throw "fromAST: string interpolation only supports Str nodes or plain text";
          EscapedNewline = _: "";
        };

      keyFromKeyName = keyName:
        match keyName {
          StaticKey = { contents, ... }: contents;
          DynamicKey = { contents, ... }: textFromPart contents;
        };
    in
    go ast;
}
