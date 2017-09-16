module Test.Util exposing (..)

import Util exposing (..)
import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string, maybe)
import String


infixQuestionMarkTests : Test
infixQuestionMarkTests =
    describe "?"
        [ test "Returns value wrapped in Just if True" <|
            \() ->
                (?) True 1
                    |> Maybe.withDefault 0
                    |> Expect.equal 1
        , test "Returns Nothing if False" <|
            \() ->
                (?) False 1
                    |> Maybe.withDefault 0
                    |> Expect.equal 0
        ]


infixEqualsColonEqualsTests : Test
infixEqualsColonEqualsTests =
    describe "=:="
        [ test "Returns second Value if second is Just" <|
            \() ->
                (=:=) (Just 1) 0
                    |> Expect.equal 1
        , test "Returns first Value if Nothing" <|
            \() ->
                (=:=) (Nothing) 0
                    |> Expect.equal 0
        , fuzz (maybe int) "Will always return int" <|
            \maybeInt ->
                (=:=) maybeInt 0
                    |> always Expect.pass
        ]


ternaryTests : Test
ternaryTests =
    describe "? =:="
        [ test "Returns left (=:=) value if first (?) input is truthy" <|
            \() ->
                (True ? True =:= False)
                    |> Expect.true "Should return true"
        , test "Returns right (=:=) value if first (?) input is falsy" <|
            \() ->
                (False ? True =:= False)
                    |> Expect.false "Should return false"
        ]


reverseAppendTests : Test
reverseAppendTests =
    describe "^+"
        [ test "Reverses a string " <|
            \() ->
                (^+) " hello" "world"
                    |> Expect.equal "world hello"
        , test "Reverses a list " <|
            \() ->
                (^+) [ 0, 1, 2 ] [ 3, 4, 5 ]
                    |> Expect.equal [ 3, 4, 5, 0, 1, 2 ]
        , fuzz2 string string "Reverse string fuzz tests" <|
            \a b ->
                (^+) a b
                    |> Expect.equal (b ++ a)
        , fuzz2 (list int) (list int) "Reverse integer list fuzz tests" <|
            \a b ->
                (^+) a b
                    |> Expect.equal (b ++ a)
        ]


stringHelpersTests : Test
stringHelpersTests =
    describe "String helpers"
        [ test "len" <|
            \() ->
                len "hello"
                    |> Expect.equal 5
        , test "empty" <|
            \() ->
                empty "hello"
                    |> Expect.equal False
        , test "end" <|
            \() ->
                end 1 "hello"
                    |> Expect.equal "o"
        ]


isValidSystemReplyTests : Test
isValidSystemReplyTests =
    let
        spaceSplit =
            String.split " "

        compact =
            String.join ""

        addStop =
            flip (++) "."

        fillIfEmpty s =
            if String.isEmpty s then
                "X"
            else
                s

        wordFuzzer =
            Fuzz.map (spaceSplit >> compact >> fillIfEmpty >> addStop) string
    in
        describe "isValidSystemReply"
            [ test "Success" <|
                \() ->
                    isValidSystemReply "Nick."
                        |> Expect.equal True
            , test "Fail (no stop)" <|
                \() ->
                    isValidSystemReply "Hello"
                        |> Expect.equal False
            , test "Fail (more than one word)" <|
                \() ->
                    isValidSystemReply "Hello there."
                        |> Expect.equal False
            , fuzz wordFuzzer "Success fuzz tests" <|
                \a ->
                    isValidSystemReply a
                        |> Expect.equal True
            ]


noStopTests : Test
noStopTests =
    describe "noStopTests"
        [ test "Removes stop if present" <|
            \() ->
                noStop "hello."
                    |> Expect.equal "hello"
        , test "Returns same string if stop not present" <|
            \() ->
                let
                    res =
                        "hello"
                in
                    noStop res
                        |> Expect.equal res
        , fuzz string "Returns same string if stop not present" <|
            \str ->
                let
                    a =
                        noStop (str ++ "A.")

                    b =
                        noStop (str ++ "A..")

                    c =
                        noStop (str ++ "A...")
                in
                    ( a, b, c )
                        |> Expect.all
                            [ (\( a, _, _ ) -> Expect.equal (str ++ "A") a)
                            , (\( _, b, _ ) -> Expect.equal (str ++ "A") b)
                            , (\( _, _, c ) -> Expect.equal (str ++ "A") c)
                            ]
        ]


firstIsYTests : Test
firstIsYTests =
    describe "firstIsYTests"
        [ test "Success" <|
            \() ->
                firstIsY "yes"
                    |> Expect.true "Should be true"
        , test "Success (capitalized)" <|
            \() ->
                firstIsY "Yes"
                    |> Expect.true "Should be true"
        , test "Fail" <|
            \() ->
                firstIsY "no"
                    |> Expect.false "Should be false"
        ]


all : Test
all =
    describe "Util tests" <|
        [ Test.concat
            [ infixQuestionMarkTests
            , infixEqualsColonEqualsTests
            , ternaryTests
            , reverseAppendTests
            , stringHelpersTests
            , isValidSystemReplyTests
            , noStopTests
            , firstIsYTests
            ]
        ]
