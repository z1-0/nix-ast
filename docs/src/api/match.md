# match: Pattern Matching

Type-safe pseudo pattern matching on AST node tags.

## Syntax

```nix
match ast {
  Tag1 = handler1;
  Tag2 = handler2;
  _ = defaultHandler;
}
```

Each handler is a function that receives the matched node.

## Examples

### Simple Match

```nix
match ast {
  Sym = n: n.contents;
  _ = n: "unknown";
}
```

### Destructure

```nix
match ast {
  App = { func, arg }: "application";
  If = { cond, thenExpr, elseExpr }: "conditional";
  Let = { bindings, body }: "let expression";
  _ = n: n.tag;
}
```

### Nested Match

```nix
match ast {
  Set = { recursive, bindings }:
    if recursive then "recursive set" else "set";
  _ = n: "other";
}
```

## Handler Signatures

Each handler receives the node as its argument. You can destructure the fields:

```nix
# Full node
match ast {
  Sym = n: n;  # n is the entire node
  _ = n: n;
}

# Destructured
match ast {
  Sym = { contents }: contents;  # destructure fields
  App = { func, arg }: func;
  _ = n: n.tag;
}
```

## Wildcard

The `_` handler catches any unmatched tag:

```nix
match ast {
  Sym = n: "symbol";
  _ = n: "other: ${n.tag}";
}
```

## Use Cases

### Type Checking

```nix
isInteger = match ast {
  Constant = { contents }: syntax.isInt contents;
  _ = _: false;
};
```

### Pretty Printing

```nix
pretty = match ast {
  Sym = { contents }: contents;
  Int = { contents }: toString contents;
  Str = { contents }: "\"${contents}\"";
  _ = n: builtins.toJSON n;
};
```
