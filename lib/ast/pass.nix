let
  s = import ./syntax.nix;
  c = import ./core.nix;
in {
  rename = old: new:
    c.rewrite (
      node:
        if s.isSym node && s.getSymName node == old
        then s.mkSym new
        else node
    );

  replaceString = old: new:
    c.rewrite (
      node:
        if s.isStr node
        then let
          str = s.getStrValue node;
          replacePart = part:
            if s.isPlain part
            then part // {contents = builtins.replaceStrings [old] [new] part.contents;}
            else part;
        in
          s.mkStr (builtins.map replacePart str)
        else node
    );

  wrapWith = ns: ast: s.mkWith ns ast;

  addOverrides = bindings: ast:
    if s.isSet ast
    then ast // {bindings = s.getSetBindings ast ++ bindings;}
    else ast;

  removeBindings = names: ast: let
    keepBinding = binding: let
      pathNames = map s.getStaticKeyName (s.getNamedVarAttrPath binding);
    in
      !(s.isNamedVar binding && builtins.all (n: builtins.elem n names) pathNames);
  in
    if s.isLet ast
    then ast // {bindings = builtins.filter keepBinding (s.getLetBindings ast);}
    else if s.isSet ast
    then ast // {bindings = builtins.filter keepBinding (s.getSetBindings ast);}
    else ast;

  inline = name: ast: let
    uses = c.count (n: s.isSym n && s.getSymName n == name) ast;
    findInBindings = node: let
      bindings =
        if s.isLet node
        then s.getLetBindings node
        else if s.isSet node
        then s.getSetBindings node
        else [];
      found = builtins.filter (b: s.isNamedVar b && builtins.elem name (map s.getStaticKeyName (s.getNamedVarAttrPath b))) bindings;
    in
      if found != []
      then builtins.head found
      else null;
    findBinding = node: let
      result = findInBindings node;
    in
      if result != null
      then result
      else let
        childNodes = c.children node;
        search = i:
          if i >= builtins.length childNodes
          then null
          else let
            r = findBinding (builtins.elemAt childNodes i);
          in
            if r != null
            then r
            else search (i + 1);
      in
        search 0;
    binding = findBinding ast;
    value =
      if binding != null
      then s.getNamedVarValue binding
      else null;
    step1 =
      if uses != 1 || value == null
      then ast
      else
        c.rewrite (
          n:
            if s.isSym n && s.getSymName n == name
            then value
            else n
        )
        ast;
    step2 =
      if uses != 1 || value == null
      then step1
      else
        c.rewrite (
          n:
            if s.isLet n
            then let
              remaining =
                builtins.filter
                (b: !(s.isNamedVar b && builtins.elem name (map s.getStaticKeyName (s.getNamedVarAttrPath b))))
                (s.getLetBindings n);
            in
              if remaining == []
              then s.getLetBody n
              else n // {bindings = remaining;}
            else n
        )
        step1;
  in
    step2;

  hoistLet = c.rewrite (
    node:
      if s.isLet node && s.isLet (s.getLetBody node)
      then let
        inner = s.getLetBody node;
      in
        s.mkLet (s.getLetBindings node ++ s.getLetBindings inner) (s.getLetBody inner)
      else node
  );

  flattenSets = c.rewrite (
    node:
      if s.isBinary node && s.getBinaryOp node == "//"
      then let
        collectOperands = n:
          if s.isBinary n && s.getBinaryOp n == "//"
          then (collectOperands (s.getBinaryLeft n)) ++ (collectOperands (s.getBinaryRight n))
          else [n];
        operands = collectOperands node;
        rebuildRight = ops:
          if builtins.length ops == 1
          then builtins.head ops
          else s.mkBinary "//" (builtins.head ops) (rebuildRight (builtins.tail ops));
      in
        rebuildRight operands
      else node
  );
}
