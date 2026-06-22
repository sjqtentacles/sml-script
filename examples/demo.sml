(* demo.sml - evaluate a few Bitcoin Script (subset) programs on the stack
   machine and round-trip a P2PKH template through (de)serialization.
   Deterministic: no RNG, no clock; identical output on every run and on both
   MLton and Poly/ML. The stack is printed top-first. *)

open Script

fun showStack stk = "[" ^ String.concatWith ", " stk ^ "]"
fun showResult NONE = "NONE (script failed)"
  | showResult (SOME stk) = "SOME " ^ showStack stk

fun runLabeled label script init =
  print ("  " ^ label ^ " = " ^ showResult (eval script init) ^ "\n")

val () = print "Bitcoin Script (subset) stack machine:\n"
val () = runLabeled "[PUSH 2, PUSH 3, ADD]      " [OP_PUSH "2", OP_PUSH "3", OP_ADD] []
val () = runLabeled "[PUSH ab, PUSH ab, EQUAL]  " [OP_PUSH "ab", OP_PUSH "ab", OP_EQUAL] []
val () = runLabeled "[PUSH 1, IF yes ELSE no]   "
           [OP_PUSH "1", OP_IF, OP_PUSH "yes", OP_ELSE, OP_PUSH "no", OP_ENDIF] []
val () = runLabeled "[PUSH 0, IF yes ELSE no]   "
           [OP_PUSH "0", OP_IF, OP_PUSH "yes", OP_ELSE, OP_PUSH "no", OP_ENDIF] []
val () = runLabeled "[PUSH x, RETURN]           " [OP_PUSH "x", OP_RETURN] []

val () = print "\nP2PKH template (pubkey hash = \"deadbeef\"):\n"
val lock = p2pkh "deadbeef"
val ser = serialize lock
val () = print ("  serialized   = " ^ ser ^ "\n")
val () = print ("  round-trip ok = " ^ Bool.toString (deserialize ser = SOME lock) ^ "\n")
