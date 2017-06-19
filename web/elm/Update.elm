module Update exposing (..)

import Html exposing (Html, div)
import Navigation
import Storage
import Route exposing (setEntryPoint, setUrlWithUserId)
import Roles.User as U
import Roles.System as S
import Views.Chat
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing (field)
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



--Init Socket


initSocket : Model -> Phoenix.Socket.Socket Msg
initSocket { socket_url, name, user_id, channel_id } =
    -- Connect socket with name & user_id as payload
    -- Listen on channel_id
    Phoenix.Socket.init
        (socket_url
            ++ "?name="
            ++ name
            ++ "&user_id="
            ++ user_id
        )
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "msg" channel_id ReceiveMessage
        |> Phoenix.Socket.on "request" channel_id ReceiveRequest
        |> Phoenix.Socket.on "accept" channel_id ReceiveAccept
        |> Phoenix.Socket.on "decline" channel_id ReceiveDecline
        |> Phoenix.Socket.on "leave" channel_id ReceiveLeave



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

        -- Called to add hash of channel id
        SetUrl user_id ->
            model ! [ setUrlWithUserId user_id ]

        -- SendMsg via socket
        SendMsg str ->
            -- Replace with state checking function before sending
            Debug.log "Sent:" str
                |> always (model ! [])

        -- SendRequest via socket
        -- Give JSON object containing name & remote_id
        SendRequest ->
            sendRequest model

        -- Send Accept
        SendAccept ->
            sendAccept model

        -- Send Decline
        SendDecline ->
            sendDecline model

        -- On Receive socket
        ReceiveRequest msg ->
            receiveRequest msg model

        -- On Accept
        ReceiveAccept msg ->
            receiveAccept msg model

        -- JoinChannel
        JoinChannel ->
            joinChannel model

        -- Called after Joining
        JoinMessage _ ->
            model
                |> update (Assess)

        -- Connect
        ConnectSocket ->
            { model
              -- Prepare socket & Set JoinChannel state
                | socket = Just (initSocket model)
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



-- sendMessage helper
-- Accepts subject (e.g. 'msg')
-- JSON encoded msg
-- Model, returns (Model, Cmd Msg)


sendMessage : Subject -> JE.Value -> Model -> ( Model, Cmd Msg )
sendMessage subject msg model =
    case model.socket of
        Nothing ->
            model ! []

        Just socket ->
            let
                push_ =
                    Phoenix.Push.init subject ("user:" ++ model.user_id)
                        |> Phoenix.Push.withPayload msg

                ( socket_, cmd ) =
                    Phoenix.Socket.push push_ socket
            in
                ( { model | socket = Just socket_ }
                , Cmd.map PhoenixMsg cmd
                )



-- send details (name & remote_id)
-- Accepts model and a string subject, e.g. ('request', 'accept')


sendDetails : Model -> String -> ( Model, Cmd Msg )
sendDetails model subject =
    let
        msg =
            (JE.object
                [ ( "name", JE.string model.name )
                , ( "remote_id", JE.string model.remote_id )
                ]
            )
    in
        sendMessage subject msg model



-- send text (with body key)
-- Accepts model, subject and text.


sendText : Model -> String -> String -> ( Model, Cmd Msg )
sendText model subject text =
    let
        msg =
            (JE.object
                [ ( "body", JE.string text ) ]
            )
    in
        sendMessage subject msg model


sendRequest : Model -> ( Model, Cmd Msg )
sendRequest model =
    sendDetails model "request"


sendAccept : Model -> ( Model, Cmd Msg )
sendAccept model =
    sendDetails model "accept"


sendDecline : Model -> ( Model, Cmd Msg )
sendDecline model =
    sendText model "decline" "No thanks"



-- Receive Request
-- Save remote_id & remote_name temporarily
-- Set Stage
-- Then assess


receiveDetails : JE.Value -> Model -> Stage -> ( Model, Cmd Msg )
receiveDetails raw model stage =
    case JD.decodeValue requestMsgDecoder raw of
        Ok msg ->
            { model
                | remote_name = msg.name
                , remote_id = msg.remote_id
                , stage = stage
            }
                |> update (Assess)

        Err error ->
            ( model, Cmd.none )



-- When Request is received


receiveRequest : JE.Value -> Model -> ( Model, Cmd Msg )
receiveRequest raw model =
    receiveDetails raw model SA_ReceiveRequest



-- When Accept is received


receiveAccept : JE.Value -> Model -> ( Model, Cmd Msg )
receiveAccept raw model =
    receiveDetails raw model SA_ReceiveAccept



--- When Leave is received (ignore msg)


receiveLeave : JE.Value -> Model -> ( Model, Cmd Msg )
receiveLeave _ model =
    { model | stage = SA_ReceiveLeave }
        |> update (Assess)



-- Decoders


requestMsgDecoder : JD.Decoder RequestMessage
requestMsgDecoder =
    JD.map2 RequestMessage
        (JD.field "name" JD.string)
        (JD.field "remote_id" JD.string)


acceptMsgDecoder : JD.Decoder RequestMessage
acceptMsgDecoder =
    requestMsgDecoder



-- Subs


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.socket of
        Nothing ->
            Sub.none

        Just phxSocket ->
            Phoenix.Socket.listen phxSocket PhoenixMsg



{- Join -}


joinChannel : Model -> ( Model, Cmd Msg )
joinChannel model =
    case model.socket of
        Nothing ->
            model ! []

        Just modelSocket ->
            -- Join Channel from Channel ID in model
            let
                channel =
                    Phoenix.Channel.init (model.channel_id)
                        |> Phoenix.Channel.onJoin (always (JoinMessage model.channel_id))

                ( socket, phxCmd ) =
                    Phoenix.Socket.join channel modelSocket
            in
                ( { model | socket = Just socket }
                , Cmd.map PhoenixMsg phxCmd
                )



-- GLOBAL VIEWS


view : Model -> Html Msg
view model =
    div []
        [ Html.map User_ <| Views.Chat.view model
        ]
