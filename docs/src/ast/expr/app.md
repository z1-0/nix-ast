# App (Function Application)

## Definition

```
App { func :: Expr, arg :: Expr }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `func` | `Expr` | The function expression being applied |
| `arg` | `Expr` | The argument expression |

## Nix Source ↔ AST

```nix
# Nix
f x

# AST
{
  "tag": "App",
  "func": { "tag": "Sym", "contents": "f" },
  "arg": { "tag": "Sym", "contents": "x" }
}
```

### Chained Application
```nix
# Nix
f x y

# AST (left-associative)
{
  "tag": "App",
  "func": {
    "tag": "App",
    "func": { "tag": "Sym", "contents": "f" },
    "arg": { "tag": "Sym", "contents": "x" }
  },
  "arg": { "tag": "Sym", "contents": "y" }
}
```

## Nix Library Access

```nix
syntax.mkApp (syntax.mkSym "f") (syntax.mkSym "x")
```