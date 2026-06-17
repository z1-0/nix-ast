let
  s = import ./syntax.nix;
  c = import ./core.nix;

  boundVars = ast: let
    letNodes = c.find s.isLet ast;
    letNames =
      builtins.concatMap (
        n:
          map (b: (builtins.head (s.getNamedVarAttrPath b)).contents) (
            builtins.filter (b: s.getExprKind b == "NamedVar") (s.getLetBindings n)
          )
      )
      letNodes;

    absParamNames = node: let
      params = s.getAbsParams node;
    in
      if s.getExprKind params == "Single"
      then [params.paramName]
      else if s.getExprKind params == "ParamSet"
      then map (p: p.name) params.params
      else [];

    absNodes = c.find s.isAbs ast;
    absNames = builtins.concatMap absParamNames absNodes;
  in
    letNames ++ absNames;

  freeVars = ast: let
    bound = boundVars ast;
    allSyms =
      c.collect (
        n:
          if s.getExprKind n == "Sym"
          then let
            name = s.getSymName n;
          in
            if !(builtins.elem name bound)
            then name
            else null
          else null
      )
      ast;
  in
    allSyms;

  allStrings = ast: let
    strNodes = c.find s.isStr ast;
  in
    builtins.concatMap (
      n: let
        parts = s.getStrStr n;
      in
        if builtins.isList parts
        then
          map (p:
            if p.tag == "Plain"
            then p.contents
            else "")
          parts
        else [parts]
    )
    strNodes;

  allPaths = ast:
    c.collect (
      n:
        if s.getExprKind n == "LiteralPath"
        then s.getLiteralPathPath n
        else if s.getExprKind n == "EnvPath"
        then s.getEnvPathPath n
        else null
    )
    ast;

  depth = ast: let
    childDepths = map depth (c.children ast);
  in
    if childDepths == []
    then 1
    else
      1
      + builtins.foldl' (a: b:
        if a > b
        then a
        else b)
      0
      childDepths;

  size = ast: 1 + builtins.foldl' builtins.add 0 (map size (c.children ast));
in {
  inherit freeVars boundVars allStrings allPaths depth size;
}
