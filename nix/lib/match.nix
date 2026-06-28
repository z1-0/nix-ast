let
  # match :: Node -> AttrSet (Node -> Any) -> Any
  match =
    node: branches:
    if !(builtins.isAttrs node) || !(node ? tag) then
      throw "match: Expected AST node with a 'tag' attribute, but got: ${builtins.typeOf node}"
    else
      let
        inherit (node) tag;
        handler =
          branches.${tag} or (branches."_"
            or (throw "match: Non-exhaustive patterns for tag '${tag}'. Node: ${builtins.toJSON node}")
          );
      in
      handler node;
in
match
