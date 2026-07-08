# Internal helper functions for extracting children from non-Expr container
# nodes and rebuilding them. Used by traversal.nix.
let
  inherit (builtins) concatMap elemAt head length tail ;

  match = import ./match.nix;
in
rec {
  # stringChildren :: Node -> [Node]
  # Extract antiquoted expressions from a String node (DoubleQuoted/Indented)
  stringChildren = s: match s {
    DoubleQuoted = dq: concatMap (p: match p {
      Antiquoted = { contents, ... }: [ contents ];
      _ = _: [ ];
    }) dq.contents;
    Indented = ind: concatMap (p: match p {
      Antiquoted = { contents, ... }: [ contents ];
      _ = _: [ ];
    }) ind.parts;
  };

  # keyChildren :: Node -> [Node]
  # Extract expressions from a KeyName node
  keyChildren = key: match key {
    DynamicKey = { contents, ... }: match contents {
      Antiquoted = { contents, ... }: [ contents ];
      Plain = { contents, ... }: stringChildren contents;
      EscapedNewline = _: [ ];
    };
    StaticKey = _: [ ];
  };

  # rebuildString :: Node -> [Node] -> Int -> { result :: Node, index :: Int }
  # Rebuild a String node by replacing antiquoted expressions with new children
  rebuildString = s: cs: index:
    let
      parts = match s {
        DoubleQuoted = dq: dq.contents;
        Indented = ind: ind.parts;
      };
      goParts = acc: i: ps:
        if ps == [ ] then { result = acc; index = i; }
        else
          let p = head ps; rest = tail ps; in
          match p {
            Antiquoted = pNode: goParts (acc ++ [ (pNode // { contents = elemAt cs i; }) ]) (i + 1) rest;
            _ = _: goParts (acc ++ [ p ]) i rest;
          };
      rebuilt = goParts [ ] index parts;
    in
    {
      result = match s {
        DoubleQuoted = _: { tag = "DoubleQuoted"; contents = rebuilt.result; };
        Indented = _: s // { parts = rebuilt.result; };
      };
      index = rebuilt.index;
    };

  # rebuildKeyPath :: [Node] -> Int -> [Node] -> { result :: [Node], index :: Int }
  # Rebuild a key path by replacing antiquoted expressions with new children
  rebuildKeyPath = cs: index: keys:
    let
      go = acc: i: ks:
        if ks == [ ] then { result = acc; index = i; }
        else
          let k = head ks; rest = tail ks; in
          match k {
            DynamicKey = kNode: match kNode.contents {
              Antiquoted = _:
                go (acc ++ [ (kNode // { contents = kNode.contents // { contents = elemAt cs i; }; }) ]) (i + 1) rest;
              Plain = { contents, ... }:
                let rebuilt = rebuildString contents cs i; in
                go (acc ++ [ (kNode // { contents = rebuilt.result; }) ]) rebuilt.index rest;
              EscapedNewline = _: go (acc ++ [ kNode ]) i rest;
            };
            StaticKey = _: go (acc ++ [ k ]) i rest;
          };
    in
    go [ ] index keys;

  # bindingChildren :: [Binding] -> [Node]
  bindingChildren =
    bindings:
    concatMap (
      b:
      match b {
        Inherit = { scope, ... }: if scope != null then [ scope ] else [ ];
        NamedVar = { value, attrPath, ... }: [ value ] ++ concatMap keyChildren attrPath;
      }
    ) bindings;

  # rebuildBindings :: [Node] -> [Binding] -> [Binding]
  rebuildBindings =
    cs: bindings:
    let
      go =
        acc: index: bs:
        if bs == [ ] then
          acc
        else
          let
            b = head bs;
            rest = tail bs;
          in
          match b {
            Inherit =
              { scope, ... }:
              if scope != null then
                go (acc ++ [ (b // { scope = elemAt cs index; }) ]) (index + 1) rest
              else
                go (acc ++ [ b ]) index rest;
            NamedVar = bNode:
              let pathResult = rebuildKeyPath cs (index + 1) bNode.attrPath; in
              go (acc ++ [ (bNode // { value = elemAt cs index; attrPath = pathResult.result; }) ]) pathResult.index rest;
          };
    in
    go [ ] 0 bindings;

  # paramsChildren :: Params -> [Node]
  # Extract Expr children from a Params node (defaults in ParamSet)
  paramsChildren = params: match params {
    Param = _: [];
    ParamSet = ps:
      concatMap (pair:
        if length pair >= 2 && elemAt pair 1 != null
        then [ elemAt pair 1 ]
        else []
      ) ps.params;
  };

  # rebuildParams :: [Node] -> Int -> Params -> { result :: Params, index :: Int }
  # Rebuild a Params node by replacing default expressions with new children
  rebuildParams = cs: index: params: match params {
    Param = _: { result = params; index = index; };
    ParamSet = ps:
      let
        go = acc: i: pairs:
          if pairs == [] then { result = acc; index = i; }
          else
            let
              p = head pairs;
              rest = tail pairs;
              name = elemAt p 0;
              hasDefault = length p >= 2 && elemAt p 1 != null;
            in
            if hasDefault then
              go (acc ++ [ [name (elemAt cs i)] ]) (i + 1) rest
            else
              go (acc ++ [ [name] ]) i rest;
        rebuilt = go [] index ps.params;
      in
      {
        result = ps // { params = rebuilt.result; };
        index = rebuilt.index;
      };
  };
}
