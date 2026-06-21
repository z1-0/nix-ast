let
  match = import ./match.nix;

  compose = f: g: x: f (g x);
in rec {
  # children :: Node -> [Node]
  children = node:
    match node {
      Abs = {body, ...}: [body];
      App = {
        func,
        arg,
        ...
      }: [func arg];
      Assert = {
        cond,
        body,
        ...
      }: [cond body];
      Binary = {
        left,
        right,
        ...
      }: [left right];
      Constant = _: [];
      EnvPath = _: [];
      HasAttr = {expr, ...}: [expr];
      If = {
        cond,
        thenExpr,
        elseExpr,
        ...
      }: [cond thenExpr elseExpr];
      Let = {
        bindings,
        body,
        ...
      }: let
        bindingExprs =
          builtins.concatMap (
            b:
              match b {
                Inherit = {scope, ...}:
                  if scope != null
                  then [scope]
                  else [];
                NamedVar = {value, ...}: [value];
              }
          )
          bindings;
      in
        bindingExprs ++ [body];
      List = {contents, ...}: contents;
      LiteralPath = _: [];
      Select = {
        defaultValue,
        expr,
        ...
      }:
        [expr]
        ++ (
          if defaultValue != null
          then [defaultValue]
          else []
        );
      Set = {bindings, ...}:
        builtins.concatMap (
          b:
            match b {
              Inherit = {scope, ...}:
                if scope != null
                then [scope]
                else [];
              NamedVar = {value, ...}: [value];
            }
        )
        bindings;
      Str = {contents, ...}: let
        parts = match contents {
          DoubleQuoted = dq: dq.contents;
          Indented = ind: ind.parts;
        };
        antiquotedExprs =
          builtins.concatMap (
            p:
              match p {
                Antiquoted = {contents, ...}: [contents];
                _ = _: [];
              }
          )
          parts;
      in
        antiquotedExprs;
      Sym = _: [];
      SynHole = _: [];
      Unary = {arg, ...}: [arg];
      With = {
        namespace,
        body,
        ...
      }: [namespace body];
    };

  # contexts :: Node -> [(Node, Node -> Node)]
  # Every subnode paired with a function to replace it in its context.
  contexts = node: let
    processHoles = holesList:
      if builtins.length holesList == 0
      then []
      else let
        pair = builtins.head holesList;
        c = builtins.elemAt pair 0;
        ctx = builtins.elemAt pair 1;
        rest = builtins.tail holesList;
        subContexts = contexts c;
        mappedSubs =
          map (
            sub: let
              subNode = builtins.elemAt sub 0;
              subFn = builtins.elemAt sub 1;
            in [
              subNode
              (compose ctx subFn)
            ]
          )
          subContexts;
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
  holes = node: let
    cs = children node;
    len = builtins.length cs;
    indices = builtins.genList (x: x) len;
  in
    map (
      i: let
        c = builtins.elemAt cs i;
        replace = new:
          rebuild node (map (j:
            if j == i
            then new
            else builtins.elemAt cs j)
          indices);
      in [
        c
        replace
      ]
    )
    indices;

  # para :: (Node -> [a] -> a) -> Node -> a
  # Paramorphism: f receives the node and the recursively-computed results from children.
  para = f: node: f node (map (para f) (children node));

  # rebuild :: Node -> [Node] -> Node
  rebuild = node: cs:
    match node {
      Abs = n: n // {body = builtins.head cs;};
      App = n:
        n
        // {
          func = builtins.elemAt cs 0;
          arg = builtins.elemAt cs 1;
        };
      Assert = n:
        n
        // {
          cond = builtins.elemAt cs 0;
          body = builtins.elemAt cs 1;
        };
      Binary = n:
        n
        // {
          left = builtins.elemAt cs 0;
          right = builtins.elemAt cs 1;
        };
      Constant = n: n;
      EnvPath = n: n;
      HasAttr = n: n // {expr = builtins.head cs;};
      If = n:
        n
        // {
          cond = builtins.elemAt cs 0;
          thenExpr = builtins.elemAt cs 1;
          elseExpr = builtins.elemAt cs 2;
        };
      Let = n: let
        body = builtins.elemAt cs (builtins.length cs - 1);
        rebuildBindings = acc: index: bindings:
          if bindings == []
          then acc
          else let
            b = builtins.head bindings;
            tail = builtins.tail bindings;
          in
            match b {
              Inherit = {scope, ...}:
                if scope != null
                then rebuildBindings (acc ++ [(b // {scope = builtins.elemAt cs index;})]) (index + 1) tail
                else rebuildBindings (acc ++ [b]) index tail;
              NamedVar = bNode:
                rebuildBindings (acc ++ [(bNode // {value = builtins.elemAt cs index;})]) (index + 1) tail;
            };
        newBindings = rebuildBindings [] 0 n.bindings;
      in
        n
        // {
          bindings = newBindings;
          inherit body;
        };
      List = n: n // {contents = cs;};
      LiteralPath = n: n;
      Select = n:
        if n.defaultValue != null
        then
          n
          // {
            expr = builtins.elemAt cs 0;
            defaultValue = builtins.elemAt cs 1;
          }
        else n // {expr = builtins.head cs;};
      Set = n: let
        rebuildBindings = acc: index: bindings:
          if bindings == []
          then acc
          else let
            b = builtins.head bindings;
            tail = builtins.tail bindings;
          in
            match b {
              Inherit = {scope, ...}:
                if scope != null
                then rebuildBindings (acc ++ [(b // {scope = builtins.elemAt cs index;})]) (index + 1) tail
                else rebuildBindings (acc ++ [b]) index tail;
              NamedVar = bNode:
                rebuildBindings (acc ++ [(bNode // {value = builtins.elemAt cs index;})]) (index + 1) tail;
            };
        newBindings = rebuildBindings [] 0 n.bindings;
      in
        n // {bindings = newBindings;};
      Str = n: let
        rebuildParts = acc: index: parts:
          if parts == []
          then acc
          else let
            p = builtins.head parts;
            tail = builtins.tail parts;
          in
            match p {
              Antiquoted = pNode:
                rebuildParts (acc ++ [(pNode // {contents = builtins.elemAt cs index;})]) (index + 1) tail;
              _ = _: rebuildParts (acc ++ [p]) index tail;
            };
        newContents = match n.contents {
          DoubleQuoted = dq: dq // {contents = rebuildParts [] 0 dq.contents;};
          Indented = ind: ind // {parts = rebuildParts [] 0 ind.parts;};
        };
      in
        n // {contents = newContents;};
      Sym = n: n;
      SynHole = n: n;
      Unary = n: n // {arg = builtins.head cs;};
      With = n:
        n
        // {
          namespace = builtins.elemAt cs 0;
          body = builtins.elemAt cs 1;
        };
    };

  # rewrite :: (Node -> Maybe Node) -> Node -> Node
  # Apply a rule everywhere bottom-up; if f returns null, leave unchanged.
  rewrite = f: node:
    transform (
      x: let
        res = f x;
      in
        if res != null
        then res
        else x
    )
    node;

  # transform :: (Node -> Node) -> Node -> Node
  # Bottom-up transformation: apply f to children first, then to parent.
  transform = f: node: f (descend (transform f) node);

  # universe :: Node -> [Node]
  # All descendant nodes including the node itself.
  universe = node: [node] ++ builtins.concatMap universe (children node);
}
