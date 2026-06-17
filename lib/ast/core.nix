let
  s = import ./syntax.nix;
  inherit (s) getExprKind;

  children = node: let
    tag = getExprKind node;
  in
    if tag == "Abs"
    then [node.body]
    else if tag == "App"
    then [node.func node.arg]
    else if tag == "Assert"
    then [node.cond node.body]
    else if tag == "Binary"
    then [node.left node.right]
    else if tag == "Constant"
    then []
    else if tag == "EnvPath"
    then []
    else if tag == "HasAttr"
    then [node.expr]
    else if tag == "If"
    then [node.cond node.then_ node.else_]
    else if tag == "Let"
    then [node.body]
    else if tag == "List"
    then node.items
    else if tag == "LiteralPath"
    then []
    else if tag == "Select"
    then
      [node.expr]
      ++ (
        if node._default != null
        then [node._default]
        else []
      )
    else if tag == "Set"
    then let
      bindingExprs = builtins.filter (b: b ? tag && b.tag == "NamedVar") node.bindings;
    in
      builtins.map (b: b.value) bindingExprs
    else if tag == "Str"
    then let
      parts = node.str;
      interpolations = builtins.filter (p: p ? tag && p.tag == "Interpolation") parts;
    in
      builtins.map (p: p.expr) interpolations
    else if tag == "SynHole"
    then []
    else if tag == "Unary"
    then [node.arg]
    else if tag == "With"
    then [node.namespace node.body]
    else [];

  rebuild = node: cs: let
    tag = getExprKind node;
  in
    if tag == "Abs"
    then node // {body = builtins.head cs;}
    else if tag == "App"
    then
      node
      // {
        func = builtins.elemAt cs 0;
        arg = builtins.elemAt cs 1;
      }
    else if tag == "Assert"
    then
      node
      // {
        cond = builtins.elemAt cs 0;
        body = builtins.elemAt cs 1;
      }
    else if tag == "Binary"
    then
      node
      // {
        left = builtins.elemAt cs 0;
        right = builtins.elemAt cs 1;
      }
    else if tag == "If"
    then
      node
      // {
        cond = builtins.elemAt cs 0;
        then_ = builtins.elemAt cs 1;
        else_ = builtins.elemAt cs 2;
      }
    else if tag == "Let"
    then node // {body = builtins.head cs;}
    else if tag == "List"
    then node // {items = cs;}
    else if tag == "Select"
    then
      if node._default != null
      then
        node
        // {
          expr = builtins.head cs;
          _default = builtins.elemAt cs 1;
        }
      else node // {expr = builtins.head cs;}
    else if tag == "Unary"
    then node // {arg = builtins.head cs;}
    else if tag == "With"
    then
      node
      // {
        namespace = builtins.elemAt cs 0;
        body = builtins.elemAt cs 1;
      }
    else node;

  map = f: node:
    f (rebuild node (builtins.map (map f) (children node)));

  rewrite = f: node:
    f (rebuild node (builtins.map (rewrite f) (children node)));

  rewriteTopDown = pred: f: node:
    if pred node
    then f node
    else let
      childNodes = children node;
      childCount = builtins.length childNodes;
      recurseChild = i: rewriteTopDown pred f (builtins.elemAt childNodes i);
      mappedChildren = builtins.genList recurseChild childCount;
    in
      rebuild node mappedChildren;

  find = pred: node: let
    go = n: acc: let
      matches =
        if pred n
        then [n]
        else [];
      childNodes = children n;
      childResults = builtins.map (c: go c []) childNodes;
    in
      acc ++ matches ++ (builtins.concatLists childResults);
  in
    go node [];

  findFirst = pred: node: let
    go = n:
      if pred n
      then n
      else let
        childNodes = children n;
      in
        if builtins.length childNodes == 0
        then null
        else let
          search = i:
            if i >= builtins.length childNodes
            then null
            else let
              r = go (builtins.elemAt childNodes i);
            in
              if r != null
              then r
              else search (i + 1);
        in
          search 0;
  in
    go node;

  collect = f: node: let
    go = n: acc: let
      val = f n;
      matches =
        if val != null
        then [val]
        else [];
      childNodes = children n;
      childResults = builtins.map (c: go c []) childNodes;
    in
      acc ++ matches ++ (builtins.concatLists childResults);
  in
    go node [];

  fold = acc: f: node: let
    go = a: n: let
      a1 = f a n;
      childNodes = children n;
    in
      if builtins.length childNodes == 0
      then a1
      else builtins.foldl' go a1 childNodes;
  in
    go acc node;

  filter = pred: node:
    find pred node;

  any = pred: node: let
    go = n:
      pred n || builtins.any go (children n);
  in
    go node;

  all = pred: node: let
    go = n:
      pred n && builtins.all go (children n);
  in
    go node;

  count = pred: node:
    builtins.length (find pred node);
in {
  inherit children map rewrite rewriteTopDown find findFirst collect fold filter any all count;
}
