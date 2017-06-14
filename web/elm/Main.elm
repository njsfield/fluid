module Main exposing (..)

import Html exposing (Html, program, div)
import Page.Chat.User as U
import Page.Chat.System as S
import Data.Chat.System as I
import Views.Chat
import Model exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform)


-- MAIN


main =
    program
        { init = baseModel ! [ initName ]
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


assess : Cmd Msg
assess =
    succeed (System_ (S.Internal_ I.Assess))
        |> perform identity


initName : Cmd Msg
initName =
    I.getNameFromStorage
        |> Cmd.map (\i -> System_ (S.Internal_ i))



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
                update (System_ (S.Internal_ I.Assess)) model
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
