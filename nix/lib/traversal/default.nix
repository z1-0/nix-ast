/**
  Invariant: rebuild n (children n) == n
  descend f node = rebuild node (map f (children node))

  When adding a new AST node:
    1. Add a branch to `children` (which fields are children and their order)
    2. Add a branch to `rebuild` (reconstruct from the new children list)
    3. Keep the order consistent between the two
*/
let
  inherit (builtins) concatMap elemAt genList head length;
  inherit (import ./utils.nix)
    bindingChildren keyChildren paramsChildren
    rebuildBindings rebuildKeyPath rebuildParams rebuildString stringChildren;
  match = import ../match.nix;
in rec {

  /**
    Immediate child nodes in deterministic order.

    # Type: children :: Node -> [Node]

    # NOTE: Order MUST match the order expected by `rebuild`.
  */
  children = node: match node {
    Abs = { params, body, ... }: paramsChildren params ++ [ body ];
    App = { func, arg, ... }: [ func arg ];
    Assert = { cond, body, ... }: [ cond body ];
    Binary = { left, right, ... }: [ left right ];
    Constant = _: [ ]; EnvPath = _: [ ]; LiteralPath = _: [ ]; Sym = _: [ ]; SynHole = _: [ ];
    HasAttr = { expr, attrPath, ... }: [ expr ] ++ concatMap keyChildren attrPath;
    If = { cond, thenExpr, elseExpr, ... }: [ cond thenExpr elseExpr ];
    Let = { bindings, body, ... }: bindingChildren bindings ++ [ body ];
    List = { contents, ... }: contents;
    Select = { defaultValue, expr, selectPath, ... }:
      [ expr ] ++ concatMap keyChildren selectPath ++ (if defaultValue != null then [ defaultValue ] else [ ]);
    Set = { bindings, ... }: bindingChildren bindings;
    Str = { contents, ... }: stringChildren contents;
    Unary = { arg, ... }: [ arg ];
    With = { namespace, body, ... }: [ namespace body ];
  };

  /**
    Every subnode paired with a function to replace it in its context.

    # Type: contexts :: Node -> [(Node, Node -> Node)]
  */
  contexts = node:
    [ [ node (x: x) ] ]
    ++ concatMap (pair:
      let c = elemAt pair 0; ctx = elemAt pair 1;
      in map (sub: [ (elemAt sub 0) (x: ctx ((elemAt sub 1) x)) ]) (contexts c)
    ) (holes node);

  /**
    Apply transformation to every immediate child, then rebuild.

    # Type: descend :: (Node -> Node) -> Node -> Node
  */
  descend = f: node: rebuild node (map f (children node));

  /**
    Each immediate child paired with a function to replace it in the parent.

    # Type: holes :: Node -> [(Node, Node -> Node)]
  */
  holes = node:
    let cs = children node; len = length cs;
    in genList (i:
      let c = elemAt cs i;
      in [ c (new: rebuild node (genList (j: if j == i then new else elemAt cs j) len)) ]
    ) len;

  /**
    Paramorphism: f receives the node and the recursively-computed results from children.

    # Type: para :: (Node -> [a] -> a) -> Node -> a
  */
  para = f: node: f node (map (para f) (children node));

  /**
    Reconstructs a node with new children.

    The i-th element of `cs` replaces the i-th child returned by `children node`.

    # Type: rebuild :: Node -> [Node] -> Node

    # NOTE: Replacement order MUST match the order from `children`.
  */
  rebuild = node: cs: match node {
    Abs = n: let p = rebuildParams cs 0 n.params; in n // { params = p.result; body = elemAt cs p.index; };
    App = n: n // { func = elemAt cs 0; arg = elemAt cs 1; };
    Assert = n: n // { cond = elemAt cs 0; body = elemAt cs 1; };
    Binary = n: n // { left = elemAt cs 0; right = elemAt cs 1; };
    Constant = n: n; EnvPath = n: n; LiteralPath = n: n; Sym = n: n; SynHole = n: n;
    HasAttr = n: let p = rebuildKeyPath cs 1 n.attrPath; in n // { expr = elemAt cs 0; attrPath = p.result; };
    If = n: n // { cond = elemAt cs 0; thenExpr = elemAt cs 1; elseExpr = elemAt cs 2; };
    Let = n: n // { bindings = rebuildBindings cs n.bindings; body = elemAt cs (length cs - 1); };
    List = n: n // { contents = cs; };
    Select = n:
      let p = rebuildKeyPath cs 1 n.selectPath;
      in if n.defaultValue != null
        then n // { expr = elemAt cs 0; selectPath = p.result; defaultValue = elemAt cs p.index; }
        else n // { expr = elemAt cs 0; selectPath = p.result; };
    Set = n: n // { bindings = rebuildBindings cs n.bindings; };
    Str = n: n // { contents = (rebuildString n.contents cs 0).result; };
    Unary = n: n // { arg = head cs; };
    With = n: n // { namespace = elemAt cs 0; body = elemAt cs 1; };
  };

  /**
    Apply a rule everywhere bottom-up.

    If f returns null, leave unchanged.

    # Type: rewrite :: (Node -> Maybe Node) -> Node -> Node
  */
  rewrite = f: node: transform (x: let r = f x; in if r != null then r else x) node;

  /**
    Bottom-up: apply f to children first, then to parent.

    # Type: transform :: (Node -> Node) -> Node -> Node
  */
  transform = f: node: f (descend (transform f) node);

  /**
    All descendant nodes including the node itself.

    # Type: universe :: Node -> [Node]
  */
  universe = node: [ node ] ++ concatMap universe (children node);
}
