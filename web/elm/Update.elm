module Update exposing (..)

import Html exposing (Html, div)
import Navigation
import Storage
import Route exposing (setEntryPoint, setUrlWithUserID)
import Roles.User as U
import Roles.System as S
import Views.Chat
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD
import Types exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform, attempt)


-- Base Model


baseModel : Model
baseModel =
    { val = ""
    , rest = 1100
    , name = ""
    , user_id = ""
    , remote_id = ""
    , turn = Open
    , placeholder = "Initialising..."
    , state = SystemType_Initialize
    , socket = Nothing
    , socket_url = ""
    }



-- Init


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init { user_id, socket_url } location =
    -- Set Entry Point (Joining / Creating)
    let
        model =
            setEntryPoint location baseModel
    in
        -- Store Flags
        { model
            | user_id = user_id
            , socket_url = socket_url
        }
            ! [ getNameFromStorage ]



--Init Socket


initSocket : Model -> Phoenix.Socket.Socket Msg
initSocket { socket_url, name, user_id } =
    let
        room =
            "user:" ++ user_id
    in
        Phoenix.Socket.init
            (socket_url
                ++ "?name="
                ++ name
                ++ "&user_id="
                ++ user_id
            )
            |> Phoenix.Socket.withDebug
            |> Phoenix.Socket.on "msg" room ReceiveMessage



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

        -- When User sends message
        -- Mainly for typing, if they send UserFinishedTyping
        -- assess is called.
        -- Otherwise map (and call SendMsg if typing)
        User_ userMsg ->
            (userMsg == UserFinishedTyping)
                ? (update Assess model)
                =:= (U.update userMsg model
                        |> Tuple.mapSecond (Cmd.map User_ >> (sendIfTyping userMsg))
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

        -- Called after URL change action
        UrlChange _ ->
            (update Assess model)

        -- SendMsg via socket
        SendMsg str ->
            -- Replace with state checking function before sending
            Debug.log "Sent:" str
                |> always (model ! [])

        -- JoinChannel
        JoinChannel ->
            case model.socket of
                Nothing ->
                    model ! []

                Just modelSocket ->
                    let
                        channel =
                            Phoenix.Channel.init ("user:" ++ model.user_id)

                        ( socket, phxCmd ) =
                            Phoenix.Socket.join channel modelSocket
                    in
                        ( { model | socket = Just socket }
                        , Cmd.map PhoenixMsg phxCmd
                        )

        -- Connect
        ConnectSocket ->
            { model
              -- Prepare socket & Set JoinChannel state
                | socket = Just (initSocket model)
                , state = SystemAction_JoinChannel
            }
                |> update Assess

        -- Handle Messages From Phoenix
        PhoenixMsg msg ->
            case model.socket of
                Nothing ->
                    model ! []

                Just modelSocket ->
                    let
                        ( socket, phxCmd ) =
                            Phoenix.Socket.update msg modelSocket
                    in
                        ( { model | socket = Just socket }
                        , Cmd.map PhoenixMsg phxCmd
                        )

        _ ->
            model ! []



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



-- Save name, call Assess after


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

        -- 3. After system asked for name
        SystemType_NamePrompt ->
            { model | val = "", state = UserType_Name } ! []

        -- 4. After user has typed name (if valid) then send name
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

        -- 7. After welcome, set Url (if remote_id not present)
        SystemType_Welcome ->
            if (String.isEmpty model.remote_id) then
                { model | val = "", state = SystemAction_SetUrl } ! [ setUrlWithUserID model.user_id ]
            else
                { model | val = "", state = SystemType_ConnectSocket } ! [ sysInput ]

        -- 8 (a.1) After setting URL
        SystemAction_SetUrl ->
            { model | state = SystemType_SetUrl } ! [ sysInput ]

        -- 8 (a. 2) After explanation. Type connect
        SystemType_SetUrl ->
            { model | val = "", state = SystemType_ConnectSocket } ! [ sysInput ]

        -- 9. Perform Connect
        SystemType_ConnectSocket ->
            { model | state = SystemAction_ConnectSocket } ! [ connectSocket ]

        -- 9. Connect
        SystemAction_JoinChannel ->
            -- TODO: Check if remote in Joining/Creating
            { model | val = "", placeholder = "Please share this URL", state = User_Idle } ! [ joinChannel ]

        -- 10. Join
        -- SystemAction_JoinChannel ->
        --     model ! []
        _ ->
            model ! []



-- Prompt System to Start Typing


sysInput : Cmd Msg
sysInput =
    do (System_ SystemType)



-- Connect


connectSocket : Cmd Msg
connectSocket =
    do (ConnectSocket)


joinChannel : Cmd Msg
joinChannel =
    do (JoinChannel)



-- If User is typing, batch cmd with
-- both cmd & SendMsg


sendIfTyping : UserMsg -> Cmd Msg -> Cmd Msg
sendIfTyping msg cmd =
    case msg of
        UserType s ->
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
