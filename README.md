# sml-script

[![CI](https://github.com/sjqtentacles/sml-script/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-script/actions/workflows/ci.yml)

Bitcoin Script stack machine interpreter (subset) in pure Standard ML

## Installation

```
smlpkg add github.com/sjqtentacles/sml-script
smlpkg sync
```

## Usage

```sml
(* Build a P2PKH locking script: OP_DUP OP_HASH160 <hash> OP_EQUALVERIFY OP_CHECKSIG *)
val lock = Script.p2pkh "a9b7f3c2d1e4"

(* Evaluate with an unlocking stack [<sig>, <pubkey>] *)
val result = Script.eval lock ["deadbeef", "a9b7f3c2d1e4"]
(* => SOME [] on success, NONE on failure *)

(* Inline script construction *)
val script : Script.script =
  [ Script.OP_PUSH "hello"
  , Script.OP_DUP
  , Script.OP_EQUAL
  ]

(* Serialise / deserialise *)
val s   = Script.serialize script     (* "OP_PUSH hello OP_DUP OP_EQUAL" *)
val s'  = Script.deserialize s        (* SOME [...] *)
```

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
evaluates a few scripts on the stack machine (arithmetic, equality, an
`IF/ELSE` branch, and an aborting `OP_RETURN`) and round-trips a P2PKH template
through (de)serialization. The stack is printed top-first:

```
$ make example
Bitcoin Script (subset) stack machine:
  [PUSH 2, PUSH 3, ADD]       = SOME [5]
  [PUSH ab, PUSH ab, EQUAL]   = SOME [1]
  [PUSH 1, IF yes ELSE no]    = SOME [yes]
  [PUSH 0, IF yes ELSE no]    = SOME [no]
  [PUSH x, RETURN]            = NONE (script failed)

P2PKH template (pubkey hash = "deadbeef"):
  serialized   = DUP HASH160 PUSH:deadbeef EQUALVERIFY CHECKSIG
  round-trip ok = true
```

## Testing

```
make test       # MLton
make test-poly  # Poly/ML
make example    # build + run the demo
```

## License

MIT
