# Invariant: rebuild n (children n) == n
# descend f node = rebuild node (map f (children node))
#
# When adding a new AST node:
#   1. Add a branch to `children` — which fields are children and their order
#   2. Add a branch to `rebuild` — reconstruct from the new children list
#   3. Keep the order consistent between the two

let
  inherit (builtins) concatMap elemAt genList head length tail ;

  match = import ./match.nix;

  # --- Key path helpers ---

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
in
rec {
  # children :: Node -> [Node]
  #
  # Returns the immediate child nodes in a deterministic order.
  # CONTRACT: The order returned here MUST match the order expected by `rebuild`.
  # See module documentation for details.
  children =
    node:
    match node {
      Abs = { body, ... }: [ body ];
      App = { func, arg, ... }: [ func arg ];
      Assert = { cond, body, ... }: [ cond body ];
      Binary = { left, right, ... }: [ left right ];
      Constant = _: [ ];
      EnvPath = _: [ ];
      HasAttr = { expr, attrPath, ... }: [ expr ] ++ concatMap keyChildren attrPath;
      If = { cond, thenExpr, elseExpr, ... }: [ cond thenExpr elseExpr ];
      Let = { bindings, body, ... }: bindingChildren bindings ++ [ body ];
      List = { contents, ... }: contents;
      LiteralPath = _: [ ];
      Select = { defaultValue, expr, selectPath, ... }: [ expr ] ++ concatMap keyChildren selectPath ++ (if defaultValue != null then [ defaultValue ] else [ ]);
      Set = { bindings, ... }: bindingChildren bindings;
      Str = { contents, ... }: stringChildren contents;
      Sym = _: [ ];
      SynHole = _: [ ];
      Unary = { arg, ... }: [ arg ];
      With = { namespace, body, ... }: [ namespace body ];
    };

  # contexts :: Node -> [(Node, Node -> Node)]
  # Every subnode paired with a function to replace it in its context.
  contexts =
    node:
    let
      processHoles =
        holesList:
        if length holesList == 0 then
          [ ]
        else
          let
            pair = head holesList;
            c = elemAt pair 0;
            ctx = elemAt pair 1;
            rest = tail holesList;
            subContexts = contexts c;
            mappedSubs = map (
              sub:
              let
                subNode = elemAt sub 0;
                subFn = elemAt sub 1;
              in
              [
                subNode
                (x: ctx (subFn x))
              ]
            ) subContexts;
          in
          mappedSubs ++ processHoles rest;
    in
    [
      [
        node
        (x: x)
      ]
    ]
    ++ processHoles (holes node);

  # descend :: (Node -> Node) -> Node -> Node
  # Apply a transformation to every immediate child, then rebuild.
  descend = f: node: rebuild node (map f (children node));

  # holes :: Node -> [(Node, Node -> Node)]
  # Each immediate child paired with a function to replace it in the parent.
  holes =
    node:
    let
      cs = children node;
      len = length cs;
      indices = genList (x: x) len;
    in
    map (
      i:
      let
        c = elemAt cs i;
        replace = new: rebuild node (map (j: if j == i then new else elemAt cs j) indices);
      in
      [ c replace ]
    ) indices;

  # para :: (Node -> [a] -> a) -> Node -> a
  # Paramorphism: f receives the node and the recursively-computed results from children.
  para = f: node: f node (map (para f) (children node));

  # rebuild :: Node -> [Node] -> Node
  #
  # Reconstructs a node with new children. The i-th element of `cs` replaces
  # the i-th child returned by `children node`.
  # CONTRACT: The replacement order MUST match the order from `children`.
  # See module documentation for details.
  rebuild =
    node: cs:
    match node {
      Abs = n: n // { body = head cs; };
      App =
        n:
        n
        // {
          func = elemAt cs 0;
          arg = elemAt cs 1;
        };
      Assert =
        n:
        n
        // {
          cond = elemAt cs 0;
          body = elemAt cs 1;
        };
      Binary =
        n:
        n
        // {
          left = elemAt cs 0;
          right = elemAt cs 1;
        };
      Constant = n: n;
      EnvPath = n: n;
      HasAttr =
        n:
        let pathResult = rebuildKeyPath cs 1 n.attrPath; in
        n // { expr = elemAt cs 0; attrPath = pathResult.result; };
      If =
        n:
        n
        // {
          cond = elemAt cs 0;
          thenExpr = elemAt cs 1;
          elseExpr = elemAt cs 2;
        };
      Let =
        n:
        n
        // {
          bindings = rebuildBindings cs n.bindings;
          body = elemAt cs (length cs - 1);
        };
      List = n: n // { contents = cs; };
      LiteralPath = n: n;
      Select =
        n:
        let pathResult = rebuildKeyPath cs 1 n.selectPath; in
        if n.defaultValue != null then
          n
          // {
            expr = elemAt cs 0;
            selectPath = pathResult.result;
            defaultValue = elemAt cs pathResult.index;
          }
        else
          n // { expr = elemAt cs 0; selectPath = pathResult.result; };
      Set = n: n // { bindings = rebuildBindings cs n.bindings; };
      Str = n: n // { contents = (rebuildString n.contents cs 0).result; };
      Sym = n: n;
      SynHole = n: n;
      Unary = n: n // { arg = head cs; };
      With =
        n:
        n
        // {
          namespace = elemAt cs 0;
          body = elemAt cs 1;
        };
    };

  # rewrite :: (Node -> Maybe Node) -> Node -> Node
  # Apply a rule everywhere bottom-up; if f returns null, leave unchanged.
  rewrite =
    f: node:
    transform (
      x:
      let
        res = f x;
      in
      if res != null then res else x
    ) node;

  # transform :: (Node -> Node) -> Node -> Node
  # Bottom-up transformation: apply f to children first, then to parent.
  transform = f: node: f (descend (transform f) node);

  # universe :: Node -> [Node]
  # All descendant nodes including the node itself.
  universe = node: [ node ] ++ concatMap universe (children node);
}
