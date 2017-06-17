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


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init { user_id } location =
    let
        model =
            setEntryPoint location baseModel
    in
        { model | user_id = user_id } ! [ getNameFromStorage ]



-- GLOBAL MSG


type Msg
    = User_ U.Msg
    | System_ S.Msg
    | UrlChange Navigation.Location
    | Assess
    | SendMsg Val
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
                        |> Tuple.mapSecond (Cmd.map User_ >> (sendIfTyping userMsg))
                    )

        System_ sysMsg ->
            (sysMsg == S.SystemFinishedTyping)
                ? (update Assess model)
                =:= (S.update sysMsg model
                        |> Tuple.mapSecond (Cmd.map System_)
                    )

        UrlChange _ ->
            (update Assess model)

        SendMsg str ->
            Debug.log "Sent:" str
                |> always (model ! [])


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
            (isValidSystemReply model.val)
                ? ({ model | state = SystemAction_SaveName } ! [ saveNameToStorage (noStop model.val) ])
                =:= (model ! [])

        -- 5 (a). System should type Welcome after saving
        SystemAction_SaveName ->
            { model | val = "", name = model.val, state = SystemType_Welcome } ! [ sysInput ]

        -- 6 (b). System should type Welcome after loading
        SystemAction_LoadName ->
            { model | name = model.val, state = SystemType_Welcome } ! [ sysInput ]

        -- 7. After welcome, set url (if creating room)
        SystemType_Welcome ->
            if (model.entry == Creating) then
                { model | val = "", state = SystemAction_SetUrl } ! [ setUrlWithUserID model.user_id ]
            else
                { model | val = "", state = SystemType_JoinChannel } ! [ sysInput ]

        -- 8 (a.1) After setting URL
        SystemAction_SetUrl ->
            { model | state = SystemType_SetUrl } ! [ sysInput ]

        -- 8 (a. 2) After explanation. Join
        SystemType_SetUrl ->
            { model | val = "", state = SystemType_JoinChannel } ! [ sysInput ]

        SystemAction_JoinChannel ->
            model ! []

        _ ->
            model ! []



-- Prompt System to Start Typing


sysInput : Cmd Msg
sysInput =
    succeed (System_ S.SystemType)
        |> perform identity



-- If User is typing, batch cmd with
-- both cmd & SendMsg


sendIfTyping : U.Msg -> Cmd Msg -> Cmd Msg
sendIfTyping msg cmd =
    case msg of
        U.UserType s ->
            succeed (SendMsg s)
                |> perform identity
                |> flip (::) [ cmd ]
                |> Cmd.batch

        _ ->
            cmd



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
