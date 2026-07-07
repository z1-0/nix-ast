# Inherit (Inherit Binding)

## Definition

```
Inherit { scope :: Maybe Expr, names :: [VarName] }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `scope` | `Maybe Expr` | Optional scope expression (`Nothing` = current scope, `Just e` = inherit from `e`) |
| `names` | `[VarName]` | List of variable names to inherit |

## Nix Source ↔ AST

### Without Scope (from current scope)
```nix
# Nix
inherit x y z;

# AST
{
  "tag": "Inherit",
  "scope": null,
  "names": ["x", "y", "z"]
}
```

### With Scope (from specific expression)
```nix
# Nix
inherit (pkgs) vim git;

# AST
{
  "tag": "Inherit",
  "scope": { "tag": "Sym", "contents": "pkgs" },
  "names": ["vim", "git"]
}
```

## Related

- [NamedVar](./named-var.md) — named variable binding
- [Let](./../expr/let.md) — let expressions using bindings
- [Set](./../expr/set.md) — attribute sets using bindings

## Nix Library Access

```nix
syntax.mkInherit null ["x" "y" "z"]
syntax.mkInherit (syntax.mkSym "pkgs") ["vim" "git"]
```