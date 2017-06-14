module Main exposing (..)

import Html exposing (Html, program, div)
import Page.Chat.User as U
import Page.Chat.System as S
import Views.Chat
import Model exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform)


-- MAIN


main =
    program
        { init = baseModel ! [ assess ]
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


assess : Cmd Msg
assess =
    succeed (System_ S.Assess)
        |> perform identity



-- GLOBAL MSG


type Msg
    = User_ U.Msg
    | System_ S.Msg



-- GLOBAL UPDATES


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        User_ userMsg ->
            if userMsg == U.Complete then
                update (System_ S.Assess) model
            else
                U.update userMsg model
                    |> Tuple.mapSecond (Cmd.map User_)

        System_ systemMsg ->
            S.update systemMsg model
                |> Tuple.mapSecond (Cmd.map System_)



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
