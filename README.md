# sml-script

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

## Testing

```
make test       # MLton
make test-poly  # Poly/ML
```

## License

MIT
