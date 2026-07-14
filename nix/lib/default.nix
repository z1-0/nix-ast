{ lib, packages }:
let
  match = import ./match.nix;
  syntax = import ./syntax.nix;
  traversal = import ./traversal;
  nix-ast-cli = pkgs: packages.${pkgs.stdenv.hostPlatform.system}.nix-ast;
in rec {
  inherit match syntax traversal;

  /**
    Evaluate ASTs to Nix values. Only JSON-serializable values supported.

    # Type: eval :: pkgs -> [AST] -> [a]
    # NOTE: IFD (Import From Derivation).
  */
  eval = pkgs: asts: builtins.fromJSON (builtins.readFile (pkgs.runCommand "nix-ast-eval" {
    nativeBuildInputs = [ (nix-ast-cli pkgs) ];
  } "nix-ast eval < ${pkgs.writeText "asts.json" (builtins.toJSON asts)} > $out"));

  /**
    Parse .nix files into AST values.

    # Type: parse :: pkgs -> [Path] -> [AST]
    # NOTE: IFD (Import From Derivation).
  */
  parse = pkgs: paths: builtins.fromJSON (builtins.readFile (pkgs.runCommand "nix-ast-parse" {
    nativeBuildInputs = [ (nix-ast-cli pkgs) ];
  } "nix-ast parse < ${pkgs.writeText "paths.json" (builtins.toJSON paths)} > $out"));

  /**
    Render ASTs to importable .nix files (named `<n>`.nix by index).

    # Type: render :: pkgs -> [AST] -> [Path]
    # NOTE: IFD (Import From Derivation).
  */
  render = pkgs: asts:
    let dir = pkgs.runCommand "nix-ast-render" { nativeBuildInputs = [ (nix-ast-cli pkgs) ]; } ''
      mkdir -p $out
      nix-ast render --out-dir $out < ${pkgs.writeText "serialize.json" (builtins.toJSON asts)}
    '';
    in lib.imap0 (i: _: "${dir}/${toString i}.nix") asts;

  /**
    Convert a Nix value to its AST (recurses into attrsets and lists).

    # Type: toAST :: a -> AST
    # WARNING: Functions and derivations will raise an error.
  */
  toAST = value:
    let go = v: with builtins;
      if isBool v then syntax.mkBool v
      else if isInt v then syntax.mkInt v
      else if isFloat v then syntax.mkFloat v
      else if isNull v then syntax.mkNull
      else if isString v then syntax.mkStr (syntax.mkDoubleQuoted [ (syntax.mkPlain v) ])
      else if isPath v then syntax.mkLiteralPath (toString v)
      else if isList v then syntax.mkList (map go v)
      else if isFunction v then throw "toAST: cannot convert function to AST"
      else if isAttrs v then
        if v ? type && v.type == "derivation"
        then throw "toAST: cannot convert derivation to AST"
        else syntax.mkSet false (lib.mapAttrsToList (name: val: syntax.mkNamedVar [ (syntax.mkStaticKey name) ] (go val)) v)
      else throw "toAST: unsupported Nix type";
    in go value;

  /**
    Convert an AST to a Nix value (inverse of toAST).

    # Type: fromAST :: AST -> a

    # NOTE:
    - Pure evaluation, no IFD, runs entirely in Nix.
    - Paths returned as strings.
    - Interpolation only supports Str nodes or plain text.
  */
  fromAST = ast:
    let
      go = node: match node {
        Constant = { contents, ... }: match contents {
          Int = { contents, ... }: contents;
          Float = { contents, ... }: contents;
          Bool = { contents, ... }: contents;
          Uri = { contents, ... }: contents;
          Null = _: null;
          _ = _: throw "fromAST: unsupported atom type '${contents.tag}'";
        };
        Str = { contents, ... }: match contents {
          DoubleQuoted = { contents, ... }: builtins.concatStringsSep "" (map textFromPart contents);
          Indented = { parts, ... }: builtins.concatStringsSep "" (map textFromPart parts);
        };
        EnvPath = { contents, ... }: contents;
        LiteralPath = { contents, ... }: contents;
        List = { contents, ... }: map go contents;
        Set = { recursive, bindings, ... }:
          if recursive then throw "fromAST: cannot convert recursive set to Nix value"
          else lib.listToAttrs (lib.concatMap (binding: match binding {
            NamedVar = { attrPath, value, ... }:
              [ { name = keyFromKeyName (builtins.head attrPath); value = go value; } ];
            Inherit = { scope, names, ... }:
              if scope == null then throw "fromAST: plain inherit (without scope) is not supported"
              else let scopeVal = go scope; in map (name: { inherit name; value = scopeVal.${name}; }) names;
          }) bindings);
        _ = _: throw "fromAST: unsupported AST node '${node.tag}'";
      };
      textFromPart = part: match part {
        Plain = { contents, ... }: if builtins.isString contents then contents else go contents;
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
    in go ast;
}
