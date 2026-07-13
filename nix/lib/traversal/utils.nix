# Internal helpers for extracting children from non-Expr container nodes
# and rebuilding them. Used by traversal/default.nix.
let
  inherit (builtins) concatMap elemAt head length tail;
  match = import ../match.nix;
  extractAntiquoted = parts: concatMap (p: match p {
    Antiquoted = { contents, ... }: [ contents ]; _ = _: [ ];
  }) parts;
  foldlWithIndex = step: init: list:
    let go = acc: i: xs:
      if xs == [ ] then { result = acc; index = i; }
      else let x = head xs; rest = tail xs; next = step acc i x;
      in go next.result next.index rest;
    in go init 0 list;
in rec {
  # stringChildren :: Node -> [Node]
  # Extract antiquoted expressions from a String node (DoubleQuoted/Indented)
  stringChildren = s: match s {
    DoubleQuoted = dq: extractAntiquoted dq.contents;
    Indented = ind: extractAntiquoted ind.parts;
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
  # Rebuild a String node by replacing antiquoted expressions with new children.
  rebuildString = s: cs: index:
    let parts = match s {
      DoubleQuoted = dq: dq.contents;
      Indented = ind: ind.parts;
    };
    step = acc: i: p: match p {
      Antiquoted = pn: { result = acc ++ [ (pn // { contents = elemAt cs i; }) ]; index = i + 1; };
      _ = _: { result = acc ++ [ p ]; index = i; };
    };
    rebuilt = foldlWithIndex step [ ] parts;
    in {
      result = match s {
        DoubleQuoted = _: { tag = "DoubleQuoted"; contents = rebuilt.result; };
        Indented = _: s // { parts = rebuilt.result; };
      };
      index = rebuilt.index;
    };

  # rebuildKeyPath :: [Node] -> Int -> [Node] -> { result :: [Node], index :: Int }
  # Rebuild a key path by replacing antiquoted expressions with new children.
  rebuildKeyPath = cs: index: keys:
    let step = acc: i: k: match k {
      DynamicKey = kn: match kn.contents {
        Antiquoted = _:
          { result = acc ++ [ (kn // { contents = kn.contents // { contents = elemAt cs i; }; }) ]; index = i + 1; };
        Plain = { contents, ... }:
          let r = rebuildString contents cs i; in
          { result = acc ++ [ (kn // { contents = r.result; }) ]; index = r.index; };
        EscapedNewline = _: { result = acc ++ [ kn ]; index = i; };
      };
      StaticKey = _: { result = acc ++ [ k ]; index = i; };
    }; in foldlWithIndex step [ ] keys;

  # bindingChildren :: [Binding] -> [Node]
  bindingChildren = bindings:
    concatMap (b: match b {
      Inherit = { scope, ... }: if scope != null then [ scope ] else [ ];
      NamedVar = { value, attrPath, ... }: [ value ] ++ concatMap keyChildren attrPath;
    }) bindings;

  # rebuildBindings :: [Node] -> [Binding] -> [Binding]
  rebuildBindings = cs: bindings:
    let step = acc: index: b: match b {
      Inherit = { scope, ... }:
        if scope != null
        then { result = acc ++ [ (b // { scope = elemAt cs index; }) ]; index = index + 1; }
        else { result = acc ++ [ b ]; index = index; };
      NamedVar = bn:
        let p = rebuildKeyPath cs (index + 1) bn.attrPath;
        in { result = acc ++ [ (bn // { value = elemAt cs index; attrPath = p.result; }) ]; index = p.index; };
    };
    rebuilt = foldlWithIndex step [ ] bindings;
    in rebuilt.result;

  # paramsChildren :: Params -> [Node]
  # Extract Expr children from a Params node (defaults in ParamSet).
  paramsChildren = params: match params {
    Param = _: [ ];
    ParamSet = ps: concatMap (pair:
      if length pair >= 2 && elemAt pair 1 != null
      then [ elemAt pair 1 ] else [ ]
    ) ps.params;
  };

  # rebuildParams :: [Node] -> Int -> Params -> { result :: Params, index :: Int }
  # Rebuild a Params node by replacing default expressions with new children.
  rebuildParams = cs: index: params: match params {
    Param = _: { result = params; index = index; };
    ParamSet = ps:
      let step = acc: i: pair:
        let name = elemAt pair 0;
            hasDefault = length pair >= 2 && elemAt pair 1 != null;
        in if hasDefault then { result = acc ++ [ [name (elemAt cs i)] ]; index = i + 1; }
           else { result = acc ++ [ [name] ]; index = i; };
          rebuilt = foldlWithIndex step [ ] ps.params;
      in { result = ps // { params = rebuilt.result; }; index = rebuilt.index; };
  };
}
