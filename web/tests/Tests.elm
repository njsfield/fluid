port module Tests exposing (..)

import Test exposing (..)
import Test.Route as Route
import Test.Util as Util
import Test.Runner.Node exposing (run, TestProgram)
import Json.Encode exposing (Value)


all : Test
all =
    describe "All tests"
        [ Route.all
        , Util.all
        ]


main : TestProgram
main =
    run emit all


port emit : ( String, Value ) -> Cmd msg
