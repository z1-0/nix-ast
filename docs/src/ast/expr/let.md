# Let (Let Bindings)

## Definition

```
Let { bindings :: [Binding], body :: Expr }
```

## Fields

| Field      | Type        | Description                                      |
| ---------- | ----------- | ------------------------------------------------ |
| `bindings` | `[Binding]` | List of local bindings (`Inherit` or `NamedVar`) |
| `body`     | `Expr`      | Body expression evaluated with bindings in scope |

## Nix Source ↔ AST

```nix
# Nix
let x = 1; y = 2; in x + y

# AST
{
  "tag": "Let",
  "bindings": [
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "x" }],
      "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
    },
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "y" }],
      "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 2 } }
    }
  ],
  "body": {
    "tag": "Binary",
    "op": "+",
    "left": { "tag": "Sym", "contents": "x" },
    "right": { "tag": "Sym", "contents": "y" }
  }
}
```

## Related

- [Binding](../binding/README.md): `Inherit` and `NamedVar` constructors
- [With](./with.md): similar but brings a set into scope

## Nix Library Access

```nix
syntax.mkLet [syntax.mkNamedVar [syntax.mkStaticKey "x"] (syntax.mkInt 1)] (syntax.mkBinary "+" (syntax.mkSym "x") (syntax.mkSym "y"))
```
