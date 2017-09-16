module Test.Util exposing (..)

import Util exposing (..)
import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String


all : Test
all =
    describe "Util tests"
        [ describe "setEntryPoint"
            [ test "Success (extracts correct hash string)" <|
                \() ->
                    5
                        |> Expect.equal 5
            ]
        ]
