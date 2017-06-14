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
            (isComplete userMsg)
                ? (sysAssess model)
                =:= (userUpdate userMsg model)

        System_ sysMsg ->
            (sysUpdate sysMsg model)

        UrlChange _ ->
            model ! []



-- User Sent complete?


isComplete : U.Msg -> Bool
isComplete =
    (==) U.Complete



-- Update Mappers


userUpdate : U.Msg -> Model -> ( Model, Cmd Msg )
userUpdate msg model =
    U.update msg model
        |> Tuple.mapSecond (Cmd.map User_)


sysUpdate : S.Msg -> Model -> ( Model, Cmd Msg )
sysUpdate msg model =
    S.update msg model
        |> Tuple.mapSecond (Cmd.map System_)



-- To System Assess


sysAssess : Model -> ( Model, Cmd Msg )
sysAssess model =
    update (System_ S.Assess) model



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
