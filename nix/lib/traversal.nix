# traversal.nix — AST traversal primitives
#
# This module provides functions for traversing and transforming Nix AST nodes.
#
# ## children/rebuild contract
#
# `children` and `rebuild` form a paired API with an implicit ordering contract:
#
#   - `children node` returns a list of child nodes in a deterministic order.
#   - `rebuild node cs` replaces the children of `node` with the list `cs`,
#     where `cs[i]` corresponds to the i-th element returned by `children node`.
#
# **Invariant**: For any node `n`:
#   rebuild n (children n) == n
#
# **Warning**: If you change the order of children returned by `children`,
# you MUST update `rebuild` to match, otherwise `descend`, `holes`, `contexts`,
# `para`, `transform`, `rewrite`, and `universe` will produce incorrect results.
#
# The `descend` function relies on this contract:
#   descend f node = rebuild node (map f (children node))
#
# ## Adding a new AST node type
#
# When adding a new constructor to the AST, you must update:
#   1. `children` — define which fields are child nodes and their order
#   2. `rebuild`  — reconstruct the node from the new children list
#   3. Keep the order consistent between both functions

let
  match = import ./match.nix;

  compose =
    f: g: x:
    f (g x);

  # bindingChildren :: [Binding] -> [Node]
  bindingChildren =
    bindings:
    builtins.concatMap (
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
            b = builtins.head bs;
            tail = builtins.tail bs;
          in
          match b {
            Inherit =
              { scope, ... }:
              if scope != null then
                go (acc ++ [ (b // { scope = builtins.elemAt cs index; }) ]) (index + 1) tail
              else
                go (acc ++ [ b ]) index tail;
            NamedVar = bNode: go (acc ++ [ (bNode // { value = builtins.elemAt cs index; }) ]) (index + 1) tail;
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
      App = { func, arg, ... }: [
        func
        arg
      ];
      Assert = { cond, body, ... }: [
        cond
        body
      ];
      Binary = { left, right, ... }: [
        left
        right
      ];
      Constant = _: [ ];
      EnvPath = _: [ ];
      HasAttr = { expr, ... }: [ expr ];
      If =
        {
          cond,
          thenExpr,
          elseExpr,
          ...
        }:
        [
          cond
          thenExpr
          elseExpr
        ];
      Let = { bindings, body, ... }: bindingChildren bindings ++ [ body ];
      List = { contents, ... }: contents;
      LiteralPath = _: [ ];
      Select =
        { defaultValue, expr, ... }: [ expr ] ++ (if defaultValue != null then [ defaultValue ] else [ ]);
      Set = { bindings, ... }: bindingChildren bindings;
      Str =
        { contents, ... }:
        let
          parts = match contents {
            DoubleQuoted = dq: dq.contents;
            Indented = ind: ind.parts;
          };
          antiquotedExprs = builtins.concatMap (
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
      With = { namespace, body, ... }: [
        namespace
        body
      ];
    };

  # contexts :: Node -> [(Node, Node -> Node)]
  # Every subnode paired with a function to replace it in its context.
  contexts =
    node:
    let
      processHoles =
        holesList:
        if builtins.length holesList == 0 then
          [ ]
        else
          let
            pair = builtins.head holesList;
            c = builtins.elemAt pair 0;
            ctx = builtins.elemAt pair 1;
            rest = builtins.tail holesList;
            subContexts = contexts c;
            mappedSubs = map (
              sub:
              let
                subNode = builtins.elemAt sub 0;
                subFn = builtins.elemAt sub 1;
              in
              [
                subNode
                (compose ctx subFn)
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
  descend = f: node: rebuild node (builtins.map f (children node));

  # holes :: Node -> [(Node, Node -> Node)]
  # Each immediate child paired with a function to replace it in the parent.
  holes =
    node:
    let
      cs = children node;
      len = builtins.length cs;
      indices = builtins.genList (x: x) len;
    in
    map (
      i:
      let
        c = builtins.elemAt cs i;
        replace = new: rebuild node (map (j: if j == i then new else builtins.elemAt cs j) indices);
      in
      [
        c
        replace
      ]
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
      Abs = n: n // { body = builtins.head cs; };
      App =
        n:
        n
        // {
          func = builtins.elemAt cs 0;
          arg = builtins.elemAt cs 1;
        };
      Assert =
        n:
        n
        // {
          cond = builtins.elemAt cs 0;
          body = builtins.elemAt cs 1;
        };
      Binary =
        n:
        n
        // {
          left = builtins.elemAt cs 0;
          right = builtins.elemAt cs 1;
        };
      Constant = n: n;
      EnvPath = n: n;
      HasAttr = n: n // { expr = builtins.head cs; };
      If =
        n:
        n
        // {
          cond = builtins.elemAt cs 0;
          thenExpr = builtins.elemAt cs 1;
          elseExpr = builtins.elemAt cs 2;
        };
      Let =
        n:
        let
          body = builtins.elemAt cs (builtins.length cs - 1);
        in
        n
        // {
          bindings = rebuildBindings cs n.bindings;
          inherit body;
        };
      List = n: n // { contents = cs; };
      LiteralPath = n: n;
      Select =
        n:
        if n.defaultValue != null then
          n
          // {
            expr = builtins.elemAt cs 0;
            defaultValue = builtins.elemAt cs 1;
          }
        else
          n // { expr = builtins.head cs; };
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
                p = builtins.head parts;
                tail = builtins.tail parts;
              in
              match p {
                Antiquoted =
                  pNode:
                  rebuildParts (acc ++ [ (pNode // { contents = builtins.elemAt cs index; }) ]) (index + 1) tail;
                _ = _: rebuildParts (acc ++ [ p ]) index tail;
              };
          newContents = match n.contents {
            DoubleQuoted = dq: dq // { contents = rebuildParts [ ] 0 dq.contents; };
            Indented = ind: ind // { parts = rebuildParts [ ] 0 ind.parts; };
          };
        in
        n // { contents = newContents; };
      Sym = n: n;
      SynHole = n: n;
      Unary = n: n // { arg = builtins.head cs; };
      With =
        n:
        n
        // {
          namespace = builtins.elemAt cs 0;
          body = builtins.elemAt cs 1;
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
  universe = node: [ node ] ++ builtins.concatMap universe (children node);
}
