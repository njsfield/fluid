module Update exposing (..)

import Html exposing (Html, div)
import Navigation
import Storage
import Route exposing (setEntryPoint, setUrlWithUserID)
import Roles.User as U
import Roles.System as S
import Views.Chat
import Model exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform, attempt)


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        model =
            setEntryPoint location baseModel
    in
        model ! [ getNameFromStorage ]



-- GLOBAL MSG


type Msg
    = User_ U.Msg
    | System_ S.Msg
    | UrlChange Navigation.Location
    | Assess
    | LoadName (Maybe Val)



-- GLOBAL UPDATES


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Assess ->
            assess model

        LoadName maybeName ->
            maybeStartFromWelcome maybeName model

        User_ userMsg ->
            (userMsg == U.UserFinishedTyping)
                ? (update Assess model)
                =:= (U.update userMsg model
                        |> Tuple.mapSecond (Cmd.map User_)
                    )

        System_ sysMsg ->
            (sysMsg == S.SystemFinishedTyping)
                ? (update Assess model)
                =:= (S.update sysMsg model
                        |> Tuple.mapSecond (Cmd.map System_)
                    )

        UrlChange _ ->
            model ! []


getNameFromStorage : Cmd Msg
getNameFromStorage =
    Storage.get "name"
        |> attempt
            (\res ->
                case res of
                    Ok name ->
                        LoadName name

                    Err _ ->
                        LoadName Nothing
            )


saveNameToStorage : Name -> Cmd Msg
saveNameToStorage name =
    Storage.set "name" name
        |> attempt (always Assess)



-- Maybe start from Welcome state if name loaded?


maybeStartFromWelcome : Maybe Name -> Model -> ( Model, Cmd Msg )
maybeStartFromWelcome maybeName model =
    case maybeName of
        -- If name
        Just name ->
            -- Store val as name, set state to welcome
            { model
                | val = name
                , name = name
                , state = SystemAction_LoadName
            }
                |> update (Assess)

        Nothing ->
            update (Assess) model



{-
   Main Assess
   Toggles through next state
   depending on state
-}


assess : Model -> ( Model, Cmd Msg )
assess model =
    -- First check state
    case model.state of
        -- 1. System type initialise
        SystemType_Initialize ->
            { model | state = SystemType_Introduction } ! [ sysInput ]

        -- 2. System type introduction
        SystemType_Introduction ->
            { model | val = "", state = SystemType_NamePrompt } ! [ sysInput ]

        -- 3. Save name (with val)
        SystemType_NamePrompt ->
            { model | val = "", state = UserType_Name } ! []

        -- 4. Save name (with val)
        UserType_Name ->
            { model | state = SystemAction_SaveName } ! [ saveNameToStorage (noStop model.val) ]

        -- 5 (a). System should type Welcome after saving
        SystemAction_SaveName ->
            { model | val = "", name = model.val, state = SystemType_Welcome } ! [ sysInput ]

        -- 6 (b). System should type Welcome after loading
        SystemAction_LoadName ->
            { model | name = model.val, state = SystemType_Welcome } ! [ sysInput ]

        -- 7. System should
        SystemType_Welcome ->
            { model | name = model.val, state = SystemType_Connect } ! []

        _ ->
            model ! []



-- Prompt System to Start Typing


sysInput : Cmd Msg
sysInput =
    succeed (System_ S.SystemType)
        |> perform identity



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
