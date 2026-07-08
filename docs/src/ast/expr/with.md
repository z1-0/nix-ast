# With (With Expression)

## Definition

```
With { namespace :: Expr, body :: Expr }
```

## Fields

| Field       | Type   | Description                                                  |
| ----------- | ------ | ------------------------------------------------------------ |
| `namespace` | `Expr` | The set expression whose attributes are brought into scope   |
| `body`      | `Expr` | Body expression evaluated with namespace attributes in scope |

## Description

`With` brings all attributes of the `namespace` set into the lexical scope of `body`. This allows referencing `pkgs.hello` as just `hello` within the body.

## Nix Source ↔ AST

```nix
# Nix
with pkgs; hello

# AST
{
  "tag": "With",
  "namespace": { "tag": "Sym", "contents": "pkgs" },
  "body": { "tag": "Sym", "contents": "hello" }
}
```

## Related

- [Let](./let.md) — similar but with explicit bindings

## Nix Library Access

```nix
syntax.mkWith (syntax.mkSym "pkgs") (syntax.mkSym "hello")
```
