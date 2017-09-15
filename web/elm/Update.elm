module Update exposing (..)

import Html exposing (Html, div)
import Navigation
import Storage
import Route exposing (setEntryPoint, setUrlWithUserId)
import Roles.User as U
import Roles.Remote as R
import Roles.System as S
import Views.Chat
import Types exposing (..)
import Util exposing (..)
import Assess exposing (..)
import Task exposing (succeed, perform, attempt)


-- Base Model


baseModel : Model
baseModel =
    { val = ""
    , rest = 1100
    , name = ""
    , user_id = ""
    , channel_id = ""
    , remote_id = ""
    , remote_name = ""
    , turn = Open
    , placeholder = "Initialising..."
    , stage = ST_Introduction
    , socket = Nothing
    , socket_url = ""
    , entry = Creating
    }



-- Init


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init { user_id, socket_url } location =
    -- Set Entry Point (Joining / Creating)
    let
        model =
            setEntryPoint location baseModel
    in
        -- Store Flags, make channel_id from user_id
        { model
            | user_id = user_id
            , channel_id = "user:" ++ user_id
            , socket_url = socket_url
        }
            ! [ getNameFromStorage ]



-- GLOBAL UPDATES


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Global assess, used to cycle through state
        Assess ->
            assess model

        -- Called on load
        -- (after getting name from local storage)
        -- Leads to assess
        LoadName maybeName ->
            maybeStartFromWelcome maybeName model

        -- Called Via assess
        SaveName name ->
            model ! [ saveNameToStorage name ]

        -- When User sends message
        -- Mainly for typing, if they send UserFinishedTyping
        -- assess is called.
        -- Otherwise map (and call SendMsg if typing)
        User_ userMsg ->
            (userMsg == UserFinishedTyping)
                ? (update Assess model)
                =:= (U.update userMsg model
                        |> Tuple.mapSecond (Cmd.map User_ >> (sendIfTyping userMsg model))
                    )

        -- When System sends message
        -- Mainly for typing, if they send SystemFinishedTyping
        -- assess is called.
        System_ sysMsg ->
            (sysMsg == SystemFinishedTyping)
                ? (update Assess model)
                =:= (S.update sysMsg model
                        |> Tuple.mapSecond (Cmd.map System_)
                    )

        -- For all remote (and socket)
        Remote_ remoteMsg ->
            (remoteMsg == RemoteComplete)
                ? (update Assess model)
                =:= (R.update remoteMsg model
                        |> Tuple.mapSecond (Cmd.map Remote_)
                    )

        -- Called after URL change action
        UrlChange _ ->
            (update Assess model)

        -- Called to add hash of channel id
        SetUrl user_id ->
            model ! [ setUrlWithUserId user_id ]



-- attempt to get name from storage
-- Call LoadName with Maybe after


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



-- save Name to Storage


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
                , stage = SA_LoadName
            }
                |> update (Assess)

        Nothing ->
            update (Assess) model



-- If User is typing & in chat, batch cmd with
-- both cmd & SendMsg


sendIfTyping : UserMsg -> Model -> Cmd Msg -> Cmd Msg
sendIfTyping msg { stage } cmd =
    -- Check if user is typing
    case msg of
        UserType str ->
            -- Assert that user before firing send message cmd
            if stage == InChat then
                succeed (Remote_ (SendMessage str))
                    |> perform identity
                    |> flip (::) [ cmd ]
                    |> Cmd.batch
            else
                cmd

        _ ->
            cmd



-- Subs


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map Remote_ (R.subscriptions model)



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
