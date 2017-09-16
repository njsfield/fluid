port module Tests exposing (..)

import Test exposing (..)
import Test.Route as Route
import Test.Util as Util
import Test.Views.Chat as Chat
import Test.Runner.Node exposing (run, TestProgram)
import Json.Encode exposing (Value)


-- Run all of our tests


main : TestProgram
main =
    run emit <|
        Test.concat
            [ Route.all
            , Util.all
            , Chat.all
            ]


port emit : ( String, Value ) -> Cmd msg
