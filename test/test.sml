structure ScriptTests =
struct
  fun run () =
    let
      open Script
    in
      Harness.section "OP_PUSH and OP_DUP";
      let
        val stk0 = eval [OP_PUSH "hello"] []
      in
        Harness.check "push to stack" (stk0 = SOME ["hello"]);
        let
          val stk1 = eval [OP_PUSH "hello", OP_DUP] []
        in
          Harness.check "dup" (stk1 = SOME ["hello", "hello"])
        end
      end;

      Harness.section "OP_EQUAL and OP_EQUALVERIFY";
      Harness.check "equal same" (eval [OP_PUSH "a", OP_PUSH "a", OP_EQUAL] [] = SOME ["1"]);
      Harness.check "equal diff" (eval [OP_PUSH "a", OP_PUSH "b", OP_EQUAL] [] = SOME ["0"]);
      Harness.check "equalverify pass" (eval [OP_PUSH "x", OP_PUSH "x", OP_EQUALVERIFY] [] = SOME []);
      Harness.check "equalverify fail" (eval [OP_PUSH "x", OP_PUSH "y", OP_EQUALVERIFY] [] = NONE);

      Harness.section "OP_ADD and OP_SUB";
      Harness.check "add" (eval [OP_PUSH "3", OP_PUSH "4", OP_ADD] [] = SOME ["7"]);
      Harness.check "sub" (eval [OP_PUSH "3", OP_PUSH "10", OP_SUB] [] = SOME ["7"]);

      Harness.section "OP_RETURN";
      Harness.check "return fails" (eval [OP_PUSH "x", OP_RETURN] [] = NONE);

      Harness.section "OP_HASH160";
      let
        val h = case eval [OP_PUSH "hello", OP_HASH160] [] of
                  SOME [v] => v
                | _ => ""
      in
        Harness.check "hash160 produces a value" (h <> "");
        Harness.check "hash160 deterministic"
          (eval [OP_PUSH "hello", OP_HASH160] [] = eval [OP_PUSH "hello", OP_HASH160] [])
      end;

      Harness.section "P2PK template";
      let
        val scr = p2pk "mypubkey"
        val result = eval scr ["mysig", "mypubkey"]
      in
        Harness.check "p2pk eval" (result = SOME ["1"])
      end;

      Harness.section "serialize / deserialize";
      let
        val scr = [OP_DUP, OP_HASH160, OP_PUSH "abc", OP_EQUALVERIFY, OP_CHECKSIG]
        val s = serialize scr
        val scr2 = deserialize s
      in
        Harness.check "serialize roundtrip" (scr2 = SOME scr)
      end
    end
end
