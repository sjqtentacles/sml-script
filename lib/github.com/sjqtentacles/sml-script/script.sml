structure Script :> SCRIPT =
struct
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

  (* Simple hash for OP_HASH160: just a rolling hash of the input *)
  fun hash160 (s : string) : string =
    let
      val n = String.size s
      fun go i acc =
        if i >= n then acc
        else go (i + 1) (Word32.+ (Word32.* (acc, 0w31),
                                   Word32.fromInt (Char.ord (String.sub (s, i)))))
      val h = go 0 0w5381
    in
      Word32.toString h
    end

  (* Evaluate script with given stack. Returns NONE on failure. *)
  fun eval (script : script) (initStack : stack) : stack option =
    let
      fun run [] stk = SOME stk
        | run (oper :: rest) stk =
            case oper of
              OP_RETURN => NONE
            | OP_PUSH v => run rest (v :: stk)
            | OP_DUP =>
                (case stk of
                  [] => NONE
                | top :: _ => run rest (top :: stk))
            | OP_DROP =>
                (case stk of
                  [] => NONE
                | _ :: rest2 => run rest rest2)
            | OP_HASH160 =>
                (case stk of
                  [] => NONE
                | top :: rest2 => run rest (hash160 top :: rest2))
            | OP_EQUAL =>
                (case stk of
                  a :: b :: rest2 =>
                    let val result = if a = b then "1" else "0"
                    in run rest (result :: rest2) end
                | _ => NONE)
            | OP_EQUALVERIFY =>
                (case stk of
                  a :: b :: rest2 =>
                    if a = b then run rest rest2 else NONE
                | _ => NONE)
            | OP_CHECKSIG =>
                (* Stub: consume pubkey and sig, push "1" *)
                (case stk of
                  _ :: _ :: rest2 => run rest ("1" :: rest2)
                | _ => NONE)
            | OP_CHECKMULTISIG =>
                (* Stub: consume all stack items, push "1" *)
                run rest ["1"]
            | OP_ADD =>
                (case stk of
                  a :: b :: rest2 =>
                    (case (Int.fromString a, Int.fromString b) of
                      (SOME x, SOME y) => run rest (Int.toString (x + y) :: rest2)
                    | _ => NONE)
                | _ => NONE)
            | OP_SUB =>
                (case stk of
                  a :: b :: rest2 =>
                    (case (Int.fromString a, Int.fromString b) of
                      (SOME x, SOME y) => run rest (Int.toString (x - y) :: rest2)
                    | _ => NONE)
                | _ => NONE)
            | OP_IF =>
                (case stk of
                  [] => NONE
                | cond :: rest2 =>
                    let
                      (* Split the remaining ops at matching ELSE/ENDIF *)
                      fun splitAt ops depth ifBranch =
                        case ops of
                          [] => NONE
                        | OP_IF :: tl => splitAt tl (depth + 1) (OP_IF :: ifBranch)
                        | OP_ENDIF :: tl =>
                            if depth = 0 then SOME (List.rev ifBranch, [], tl)
                            else splitAt tl (depth - 1) (OP_ENDIF :: ifBranch)
                        | OP_ELSE :: tl =>
                            if depth = 0 then
                              let
                                fun findEndif ops2 depth2 elseBranch =
                                  case ops2 of
                                    [] => NONE
                                  | OP_IF :: tl2 => findEndif tl2 (depth2 + 1) (OP_IF :: elseBranch)
                                  | OP_ENDIF :: tl2 =>
                                      if depth2 = 0 then SOME (List.rev ifBranch, List.rev elseBranch, tl2)
                                      else findEndif tl2 (depth2 - 1) (OP_ENDIF :: elseBranch)
                                  | hd2 :: tl2 => findEndif tl2 depth2 (hd2 :: elseBranch)
                              in
                                findEndif tl 0 []
                              end
                            else splitAt tl depth (OP_ELSE :: ifBranch)
                        | hd :: tl => splitAt tl depth (hd :: ifBranch)
                    in
                      case splitAt rest 0 [] of
                        NONE => NONE
                      | SOME (ifBranch, elseBranch, after) =>
                          let
                            val branch = if cond = "1" then ifBranch else elseBranch
                          in
                            case run branch rest2 of
                              NONE => NONE
                            | SOME stk2 => run after stk2
                          end
                    end)
            | OP_ELSE => NONE
            | OP_ENDIF => NONE
    in
      run script initStack
    end

  fun p2pk (_ : string) = [OP_CHECKSIG]

  fun p2pkh pubkeyHash =
    [OP_DUP, OP_HASH160, OP_PUSH pubkeyHash, OP_EQUALVERIFY, OP_CHECKSIG]

  fun opToString (OP_PUSH s) = "PUSH:" ^ s
    | opToString OP_DUP = "DUP"
    | opToString OP_DROP = "DROP"
    | opToString OP_HASH160 = "HASH160"
    | opToString OP_EQUAL = "EQUAL"
    | opToString OP_EQUALVERIFY = "EQUALVERIFY"
    | opToString OP_CHECKSIG = "CHECKSIG"
    | opToString OP_CHECKMULTISIG = "CHECKMULTISIG"
    | opToString OP_ADD = "ADD"
    | opToString OP_SUB = "SUB"
    | opToString OP_IF = "IF"
    | opToString OP_ELSE = "ELSE"
    | opToString OP_ENDIF = "ENDIF"
    | opToString OP_RETURN = "RETURN"

  fun serialize (script : script) : string =
    String.concatWith " " (List.map opToString script)

  fun parseOp tok =
    if String.isPrefix "PUSH:" tok
    then SOME (OP_PUSH (String.extract (tok, 5, NONE)))
    else
      case tok of
        "DUP"          => SOME OP_DUP
      | "DROP"         => SOME OP_DROP
      | "HASH160"      => SOME OP_HASH160
      | "EQUAL"        => SOME OP_EQUAL
      | "EQUALVERIFY"  => SOME OP_EQUALVERIFY
      | "CHECKSIG"     => SOME OP_CHECKSIG
      | "CHECKMULTISIG"=> SOME OP_CHECKMULTISIG
      | "ADD"          => SOME OP_ADD
      | "SUB"          => SOME OP_SUB
      | "IF"           => SOME OP_IF
      | "ELSE"         => SOME OP_ELSE
      | "ENDIF"        => SOME OP_ENDIF
      | "RETURN"       => SOME OP_RETURN
      | _              => NONE

  fun deserialize (str : string) : script option =
    if str = "" then SOME []
    else
      let
        val tokens = String.tokens (fn c => c = #" ") str
        fun parseAll [] = SOME []
          | parseAll (t :: ts) =
              case parseOp t of
                NONE => NONE
              | SOME opcode =>
                  case parseAll ts of
                    NONE => NONE
                  | SOME rest => SOME (opcode :: rest)
      in
        parseAll tokens
      end
end
