let
  s = import ./syntax.nix;
  c = import ./core.nix;

  boundVars = ast: let
    letNodes = c.find s.isLet ast;
    letNames =
      builtins.concatMap (
        n:
          map (b: s.getStaticKeyName (builtins.head (s.getNamedVarAttrPath b))) (
            builtins.filter s.isNamedVar (s.getLetBindings n)
          )
      )
      letNodes;

    absParamNames = node: let
      params = s.getAbsParams node;
    in
      if s.isParam params
      then [s.getParamName params]
      else if s.isParamSet params
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
          if s.isSym n
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
        parts = s.getStrValue n;
      in
        if builtins.isList parts
        then
          map (p:
            if s.isPlain p
            then p.value
            else "")
          parts
        else [parts]
    )
    strNodes;

  allPaths = ast:
    c.collect (
      n:
        if s.isLiteralPath n
        then s.getLiteralPathPath n
        else if s.isEnvPath n
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
