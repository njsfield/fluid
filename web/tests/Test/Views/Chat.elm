module Test.Views.Chat exposing (..)

import Html
import Html.Attributes exposing (class)
import Views.Chat exposing (..)
import Test exposing (..)
import Types exposing (..)
import Expect exposing (..)
import Test.Helpers exposing (baseModel)
import Test.Html.Query as Query
import Test.Html.Events as Event exposing (..)
import Test.Html.Selector exposing (text, tag, boolAttribute, attribute)


viewTests : Test
viewTests =
    describe "view tests"
        [ test "Input uses val from model for its value" <|
            \() ->
                let
                    val =
                        "hello"

                    model =
                        { baseModel | val = val }
                in
                    view model
                        |> Query.fromHtml
                        |> Query.find [ tag "input" ]
                        |> Query.has
                            [ attribute "value" val
                            , boolAttribute "autofocus" True
                            ]
        , test "Input uses placeholder from model for its placeholder" <|
            \() ->
                let
                    placeholder =
                        "please await response"

                    model =
                        { baseModel | placeholder = placeholder }
                in
                    view model
                        |> Query.fromHtml
                        |> Query.find [ tag "input" ]
                        |> Query.has
                            [ attribute "placeholder" placeholder
                            ]
        , test "onInput will send user input message" <|
            \() ->
                view baseModel
                    |> Query.fromHtml
                    |> Query.find [ tag "input" ]
                    |> Event.simulate (Input "hello")
                    |> Event.expectEvent (UserType "hello")
        ]


setTachsTests : Test
setTachsTests =
    describe "setTachs tests"
        [ test "setTachs prepares correct Tachs depending on Role" <|
            \() ->
                let
                    a =
                        setTachs User

                    b =
                        setTachs Remote

                    c =
                        setTachs System
                in
                    ( a, b, c )
                        |> Expect.all
                            [ (\( a, _, _ ) -> Expect.equal (userTachs) a)
                            , (\( _, b, _ ) -> Expect.equal (remoteTachs) b)
                            , (\( _, _, c ) -> Expect.equal (systemTachs) c)
                            ]
        ]


restTests : Test
restTests =
    describe "rest tests"
        [ test "rest returns rest colour if turn is Open and val has input" <|
            \() ->
                let
                    restCol =
                        "gray"

                    testModel =
                        { baseModel | turn = Open, val = "hello" }

                    testTachs =
                        { baseTachs | restCol = restCol }
                in
                    rest testModel testTachs
                        |> Expect.equal restCol
        , test "rest returns empty string if turn is not Open" <|
            \() ->
                let
                    restCol =
                        "gray"

                    testModel =
                        { baseModel | turn = System, val = "hello" }

                    testTachs =
                        { baseTachs | restCol = restCol }
                in
                    rest testModel testTachs
                        |> Expect.equal ""
        ]


colourTests : Test
colourTests =
    describe "rest tests"
        [ test "colour returns emptyCol from tachs if val from model is empty" <|
            \() ->
                let
                    emptyCol =
                        "white"

                    testModel =
                        { baseModel | val = "" }

                    testTachs =
                        { baseTachs | emptyCol = emptyCol }
                in
                    colour testModel testTachs
                        |> Expect.equal emptyCol
        , test "colour returns typeCol from tachs if val from model is not empty" <|
            \() ->
                let
                    typeCol =
                        "blue"

                    testModel =
                        { baseModel | val = "hello" }

                    testTachs =
                        { baseTachs | typeCol = typeCol }
                in
                    colour testModel testTachs
                        |> Expect.equal typeCol
        ]


sizeTests : Test
sizeTests =
    describe "size tests"
        [ test "size returns appropriate font class depending on input length " <|
            \() ->
                let
                    strA =
                        "hello"

                    strB =
                        "hello there it's nice"

                    strC =
                        "hello there it's nice to see you again"

                    a =
                        size { baseModel | val = strA }

                    b =
                        size { baseModel | val = strB }

                    c =
                        size { baseModel | val = strC }
                in
                    ( a, b, c )
                        |> Expect.all
                            [ (\( a, _, _ ) -> Expect.equal "f1" a)
                            , (\( _, b, _ ) -> Expect.equal "f2" b)
                            , (\( _, _, c ) -> Expect.equal "f3" c)
                            ]
        , test "size returns appropriate font class is placeholder value is given " <|
            \() ->
                let
                    placeholder =
                        "hello there it's nice"

                    testModel =
                        { baseModel | placeholder = placeholder, val = "" }
                in
                    size testModel
                        |> Expect.equal "f2"
        ]


all : Test
all =
    describe "View tests" <|
        [ Test.concat
            [ viewTests
            , setTachsTests
            , restTests
            , colourTests
            , sizeTests
            ]
        ]
