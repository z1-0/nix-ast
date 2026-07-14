# Changelog

## [0.6.0](https://github.com/z1-0/nix-ast/compare/v0.5.0...v0.6.0) (2026-07-14)


### Features

* add eval command for evaluating Nix AST to JSON ([f17c504](https://github.com/z1-0/nix-ast/commit/f17c504a719b96002ca706f9d461532e62dd870b))
* add parse-batch and render-batch commands ([ea45eea](https://github.com/z1-0/nix-ast/commit/ea45eea46bcb5cafa97666f53248588d2fa50d0e))


### Bug Fixes

* add Paths_nix_ast to executable other-modules in cabal file ([cd07460](https://github.com/z1-0/nix-ast/commit/cd07460cb123339eeffa54aadbe277e11723beee))
* **parse:** restore concurrent file I/O with async for batch parse ([8716612](https://github.com/z1-0/nix-ast/commit/87166122ee28da612ae8e691f08fd9ed47d5b66a))
* remove hnix reference from binary closure via remove-references-to ([789c60a](https://github.com/z1-0/nix-ast/commit/789c60a906a18e02305cab8855538d71bab9af3e))
* remove redundant 'Single' from help text ([09f62b6](https://github.com/z1-0/nix-ast/commit/09f62b613deb2f9874e8b3890f74c528e7c65d1a))


### Performance Improvements

* add file I/O concurrency for parse-batch ([9d0e67b](https://github.com/z1-0/nix-ast/commit/9d0e67b8ce032ba8ecce04a9d96ee421431cbe88))

## [0.5.0](https://github.com/z1-0/nix-ast/compare/v0.4.0...v0.5.0) (2026-07-08)


### Features

* **cli:** reword help descriptions ([ea051c9](https://github.com/z1-0/nix-ast/commit/ea051c975a527c6391981e4720e353c3108c5f5b))
* drop types from public API, annotate exports ([6f982bd](https://github.com/z1-0/nix-ast/commit/6f982bda1a7dfffde7f8c02a5193e4a47ea420e3))


### Bug Fixes

* add Abs params to children/rebuild; extract traversal helpers ([6bd7ca4](https://github.com/z1-0/nix-ast/commit/6bd7ca4135ecc86d0589d08fe9e45e2f28fee416))
* **docs:** correct ParamSet type annotation and mkSelect argument order ([4e5e4ab](https://github.com/z1-0/nix-ast/commit/4e5e4aba44cdcfa1ecc38a122a3471f20b346542))
* **syntax:** align mkParamSet argument order with Haskell ([13bbfd3](https://github.com/z1-0/nix-ast/commit/13bbfd31f250ec2b055d34c757dab64d2c51337f))
* **syntax:** make DynamicKey use Antiquoted instead of DoubleQuoted ([fd5d52d](https://github.com/z1-0/nix-ast/commit/fd5d52dc074b871e7b71d7b3108ed78ae27abe9e))
* **traversal:** extract DynamicKey expressions in children/rebuild ([d8138cb](https://github.com/z1-0/nix-ast/commit/d8138cb0d5f64aef0e20adfc7a0db451d7dd5934))

## [0.4.0](https://github.com/z1-0/nix-ast/compare/v0.3.1...v0.4.0) (2026-07-03)


### Features

* extract NixAST.Input module from CLI ([cfa88ea](https://github.com/z1-0/nix-ast/commit/cfa88ea87eaceac3f7c8c62b170c1c6822c69104))

## [0.3.1](https://github.com/z1-0/nix-ast/compare/v0.3.0...v0.3.1) (2026-07-01)


### Bug Fixes

* **ci:** add missing list indicator in release-please workflow steps ([8a4772f](https://github.com/z1-0/nix-ast/commit/8a4772f9079a6a30cf817d3acc18a27ea855d8d3))

## [0.3.0](https://github.com/z1-0/nix-ast/compare/v0.2.0...v0.3.0) (2026-06-29)


### Features

* add lib output to flake, expose nix/lib as flake lib ([98e2b4f](https://github.com/z1-0/nix-ast/commit/98e2b4f42e551a23b0f7f97ae8a87194f1496027))
* add toAST function for converting Nix values to AST ([8412175](https://github.com/z1-0/nix-ast/commit/8412175e68bcb45b23eb27a168f21f3b52ffcf6a))
* **Convert.hs:** replace error with Either Text in op conversion ([9fc3f4c](https://github.com/z1-0/nix-ast/commit/9fc3f4c4197f0724307350347d969333ce93f40e))
* rename gen to render, add --expr and --json flags ([befb00a](https://github.com/z1-0/nix-ast/commit/befb00afb6953f589b547acf76093ac1cb465a79))
* use fileset to narrow build src ([b3218cb](https://github.com/z1-0/nix-ast/commit/b3218cbe7433b50555f87fd6e0cb71745cc7007e))


### Bug Fixes

* **CLI.hs:** detect tty stdin to prevent hang on missing input ([a1432bc](https://github.com/z1-0/nix-ast/commit/a1432bc0be857a8b0fc55fb8f28281d5581dfcaa))
* drop impure nixpkgs import, pass pkgs to IFD funcs ([d1f31ee](https://github.com/z1-0/nix-ast/commit/d1f31ee00d30075bd9b91d3e491d6229bfbe1ec7))
* encode JSON AST to UTF-8 bytes via encodeUtf8 ([4a66649](https://github.com/z1-0/nix-ast/commit/4a66649ddff85b2a2d566b2fe3b1f1edc9fe11c0))

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
