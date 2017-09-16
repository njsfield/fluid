module Test.Route exposing (..)

import Test.Helpers exposing (baseModel)
import Navigation exposing (..)
import Route exposing (setEntryPoint, buildUrl, urlHash)
import Test exposing (..)
import Expect


baseLocation : Location
baseLocation =
    { href = ""
    , host = ""
    , hostname = ""
    , protocol = ""
    , origin = ""
    , port_ = ""
    , pathname = ""
    , search = ""
    , hash = ""
    , username = ""
    , password = ""
    }


all : Test
all =
    describe "Route tests"
        [ describe "setEntryPoint"
            [ test "Success (extracts correct hash string)" <|
                \() ->
                    setEntryPoint { baseLocation | hash = "#/remote_id/eghgiehosfFF" } baseModel
                        |> .remote_id
                        |> Expect.equal "eghgiehosfFF"
            , test "Fail" <|
                \() ->
                    setEntryPoint { baseLocation | hash = "cat" } baseModel
                        |> .remote_id
                        |> Expect.equal ""
            ]
        , describe "setUrlWithUserId"
            [ test "Success" <|
                \() ->
                    buildUrl "John"
                        |> Expect.equal ("/#" ++ urlHash ++ "/John")
            ]
        ]
