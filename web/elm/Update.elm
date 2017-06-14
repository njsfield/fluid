module Update exposing (..)

import Html exposing (Html, div)
import Navigation
import Route exposing (setEntryPoint, setUrlWithUserID)
import Roles.User as U
import Roles.System as S
import Views.Chat
import Model exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform)


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        model =
            setEntryPoint location baseModel
    in
        model ! [ S.getNameFromStorage |> Cmd.map (System_) ]



-- GLOBAL MSG


type Msg
    = User_ U.Msg
    | System_ S.Msg
    | UrlChange Navigation.Location



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

        UrlChange _ ->
            model ! []



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
