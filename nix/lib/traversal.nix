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

  # bindingChildren :: [Binding] -> [Node]
  bindingChildren =
    bindings:
    concatMap (
      b:
      match b {
        Inherit = { scope, ... }: if scope != null then [ scope ] else [ ];
        NamedVar = { value, ... }: [ value ];
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
            NamedVar = bNode: go (acc ++ [ (bNode // { value = elemAt cs index; }) ]) (index + 1) rest;
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
      HasAttr = { expr, ... }: [ expr ];
      If = { cond, thenExpr, elseExpr, ... }: [ cond thenExpr elseExpr ];
      Let = { bindings, body, ... }: bindingChildren bindings ++ [ body ];
      List = { contents, ... }: contents;
      LiteralPath = _: [ ];
      Select = { defaultValue, expr, ... }: [ expr ] ++ (if defaultValue != null then [ defaultValue ] else [ ]);
      Set = { bindings, ... }: bindingChildren bindings;
      Str =
        { contents, ... }:
        let
          parts = match contents {
            DoubleQuoted = dq: dq.contents;
            Indented = ind: ind.parts;
          };
          antiquotedExprs = concatMap (
            p:
            match p {
              Antiquoted = { contents, ... }: [ contents ];
              _ = _: [ ];
            }
          ) parts;
        in
        antiquotedExprs;
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
      HasAttr = n: n // { expr = head cs; };
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
        if n.defaultValue != null then
          n
          // {
            expr = elemAt cs 0;
            defaultValue = elemAt cs 1;
          }
        else
          n // { expr = head cs; };
      Set = n: n // { bindings = rebuildBindings cs n.bindings; };
      Str =
        n:
        let
          rebuildParts =
            acc: index: parts:
            if parts == [ ] then
              acc
            else
              let
                p = head parts;
                rest = tail parts;
              in
              match p {
                Antiquoted =
                  pNode: rebuildParts (acc ++ [ (pNode // { contents = elemAt cs index; }) ]) (index + 1) rest;
                _ = _: rebuildParts (acc ++ [ p ]) index rest;
              };
          newContents = match n.contents {
            DoubleQuoted = dq: dq // { contents = rebuildParts [ ] 0 dq.contents; };
            Indented = ind: ind // { parts = rebuildParts [ ] 0 ind.parts; };
          };
        in
        n // { contents = newContents; };
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
