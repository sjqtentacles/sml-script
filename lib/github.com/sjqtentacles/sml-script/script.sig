signature SCRIPT =
sig
  datatype opcode
    = OP_PUSH of string
    | OP_DUP
    | OP_DROP
    | OP_HASH160
    | OP_EQUAL
    | OP_EQUALVERIFY
    | OP_CHECKSIG
    | OP_CHECKMULTISIG
    | OP_ADD
    | OP_SUB
    | OP_IF
    | OP_ELSE
    | OP_ENDIF
    | OP_RETURN

  type script = opcode list
  type stack  = string list

  (* Evaluate a script starting with the given stack.
     Returns SOME stack on success, NONE on failure (e.g., OP_RETURN, stack underflow, EQUALVERIFY fail). *)
  val eval : script -> stack -> stack option

  (* Standard script templates *)
  val p2pk  : string -> script   (* Pay-to-public-key: push pubkey + OP_CHECKSIG *)
  val p2pkh : string -> script   (* Pay-to-pubkey-hash: OP_DUP OP_HASH160 push-hash OP_EQUALVERIFY OP_CHECKSIG *)

  (* Simple serialization: space-separated opcode names *)
  val serialize   : script -> string
  val deserialize : string -> script option
end
