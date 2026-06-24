# Changelog

## [0.2.0](https://github.com/z1-0/nix-ast/compare/v0.1.0...v0.2.0) (2026-06-24)


### Features

* add analysis module with AST analysis utilities ([e17be4a](https://github.com/z1-0/nix-ast/commit/e17be4a11968ab4e94c9015293425c8502ff41ca))
* add core module with traversal, query, and combinators ([05075e6](https://github.com/z1-0/nix-ast/commit/05075e6bbfda3e0185d4d85157ad0ec819ae0199))
* add pass module with high-level transformations ([a1a7943](https://github.com/z1-0/nix-ast/commit/a1a79436b7876a6cb8d2e678c5c435a558a9d8fe))
* add syntax module with constructors, predicates, and accessors ([58e4d85](https://github.com/z1-0/nix-ast/commit/58e4d859a5d4503f7412335abc092f90a660d541))
* centralize tag checks in syntax.nix ([0c99e86](https://github.com/z1-0/nix-ast/commit/0c99e86dd9b157a41ef8060547c63beb2e2db367))
* convert single-parameter record constructors to Non-record constructor ([cba4dde](https://github.com/z1-0/nix-ast/commit/cba4dde67127ff83c5d09f10fbe93dc5241e4ffc))
* export syntax, core, pass, analysis modules from lib.nix ([4e4d545](https://github.com/z1-0/nix-ast/commit/4e4d545aadca5dedb37b44b4f231d59323761eec))
* pre-filter bound vars in freeVars ([be58376](https://github.com/z1-0/nix-ast/commit/be58376f96aa3933d2a682e0f9ae70fb7eb3742b))
* restructure Nix AST library with Uniplate traversal API ([cfe3fd7](https://github.com/z1-0/nix-ast/commit/cfe3fd79f817b6b82cd6a1e95e25483d19457940))
* simplify Antiquoted by fixing r type parameter to Expr ([a6873a1](https://github.com/z1-0/nix-ast/commit/a6873a17523fc22e6a60ec453a25c5ebf21df996))


### Bug Fixes

* NT.Atom Float &lt;=&gt; HT.NFloat ([692dc5d](https://github.com/z1-0/nix-ast/commit/692dc5d28534cc16541ec16d262f5008b1f5b445))

## [0.1.0](https://github.com/z1-0/nix-ast/compare/v0.2.0...v0.1.0) (2026-06-16)


### Miscellaneous Chores

* release 0.1.0 ([0f20f63](https://github.com/z1-0/nix-ast/commit/0f20f63d38c249e86300ece26dbb64fb74bb6bc8))

## [0.2.0](https://github.com/z1-0/nix-ast/compare/v0.1.2...v0.2.0) (2026-06-16)


### Features

* test ([b756004](https://github.com/z1-0/nix-ast/commit/b756004d4965e4c0f210e3769fa91f7ce24815ee))

## [0.1.2](https://github.com/z1-0/nix-ast/compare/v0.1.0...v0.1.2) (2026-06-16)


### Miscellaneous Chores

* release 0.1.2 ([bbe771a](https://github.com/z1-0/nix-ast/commit/bbe771a8f87b8a3b0d6d176c3b01bb554d5cf53e))

## [0.1.0](https://github.com/z1-0/nix-ast/compare/v0.1.0...v0.1.0) (2026-06-16)


### Miscellaneous Chores

* release 0.1.0.0 ([31a4340](https://github.com/z1-0/nix-ast/commit/31a43406f2e6c2886a9f7e1fe3b48b5e3895d85f))
