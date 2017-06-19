module Roles.Remote exposing (..)

import Types exposing (..)
import Util exposing (..)
import Task exposing (perform, succeed)
import Process exposing (sleep)
import Time exposing (millisecond)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing (field)


--Init Socket


initSocket : Model -> Phoenix.Socket.Socket RemoteMsg
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
        |> Phoenix.Socket.on "message" channel_id ReceiveMessage
        |> Phoenix.Socket.on "request" channel_id ReceiveRequest
        |> Phoenix.Socket.on "accept" channel_id ReceiveAccept
        |> Phoenix.Socket.on "deny" channel_id ReceiveDecline
        |> Phoenix.Socket.on "leave" channel_id ReceiveLeave



-- GLOBAL UPDATES


update : RemoteMsg -> Model -> ( Model, Cmd RemoteMsg )
update msg model =
    case msg of
        -- Global assess, used to cycle through state
        RemoteComplete ->
            model ! []

        -- SendMessage
        SendMessage str ->
            sendMessage str model

        -- SendRequest
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

        -- On Decline
        ReceiveDecline msg ->
            receiveDecline msg model

        -- On Leave
        ReceiveLeave msg ->
            receiveLeave msg model

        -- On Message
        ReceiveMessage msg ->
            receiveMessage msg model

        -- JoinChannel
        JoinChannel ->
            joinChannel model

        -- Called after Joining
        JoinMessage _ ->
            model ! [ complete ]

        -- Connect
        ConnectSocket ->
            { model
                | socket = Just (initSocket model)
            }
                ! [ complete ]

        -- Handle Messages From Phoenix
        PhoenixMsg msg ->
            phoenixMsg msg model

        RemoteType str ->
            { model
                | turn = Remote
                , val = reset str model
            }
                ! [ debounce model.rest <| reset str model ]

        RemoteTypeBounced str ->
            model ! ((str == model.val) ? [ complete ] =:= [])


phoenixMsg : Phoenix.Socket.Msg RemoteMsg -> Model -> ( Model, Cmd RemoteMsg )
phoenixMsg msg model =
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



-- sendMessage helper
-- Accepts subject (e.g. 'RemoteMsg')
-- JSON encoded RemoteMsg
-- Model, returns (Model, Cmd RemoteMsg)


send : Subject -> JE.Value -> Model -> ( Model, Cmd RemoteMsg )
send subject msg model =
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


sendDetails : Model -> String -> ( Model, Cmd RemoteMsg )
sendDetails model subject =
    let
        msg =
            (JE.object
                [ ( "name", JE.string model.name )
                , ( "remote_id", JE.string model.remote_id )
                ]
            )
    in
        send subject msg model



-- send text (with body key)
-- Accepts model, subject and text.


sendText : Model -> String -> String -> ( Model, Cmd RemoteMsg )
sendText model subject text =
    let
        msg =
            (JE.object
                [ ( "body", JE.string text ) ]
            )
    in
        send subject msg model


sendRequest : Model -> ( Model, Cmd RemoteMsg )
sendRequest model =
    sendDetails model "request"


sendAccept : Model -> ( Model, Cmd RemoteMsg )
sendAccept model =
    sendDetails model "accept"


sendDecline : Model -> ( Model, Cmd RemoteMsg )
sendDecline model =
    sendDetails model "deny"


sendMessage : String -> Model -> ( Model, Cmd RemoteMsg )
sendMessage str model =
    sendText model "message" str



-- Receive Request
-- Save remote_id & remote_name temporarily
-- Set Stage
-- Then assess


receiveDetails : JE.Value -> Model -> Stage -> ( Model, Cmd RemoteMsg )
receiveDetails raw model stage =
    case JD.decodeValue detailsMsgDecoder raw of
        Ok msg ->
            { model
                | remote_name = msg.name
                , remote_id = msg.remote_id
                , stage = stage
            }
                ! [ complete ]

        Err error ->
            model ! []



-- Send to Remote


receiveText : JE.Value -> Model -> Stage -> ( Model, Cmd RemoteMsg )
receiveText raw model stage =
    case JD.decodeValue textMsgDecoder raw of
        Ok { body } ->
            update (RemoteType body) model

        Err error ->
            model ! []



-- When Request is received


receiveRequest : JE.Value -> Model -> ( Model, Cmd RemoteMsg )
receiveRequest raw model =
    receiveDetails raw model SA_ReceiveRequest



-- When Accept is received


receiveAccept : JE.Value -> Model -> ( Model, Cmd RemoteMsg )
receiveAccept raw model =
    receiveDetails raw model SA_ReceiveAccept



--- When Leave is received (ignore RemoteMsg)


receiveDecline : JE.Value -> Model -> ( Model, Cmd RemoteMsg )
receiveDecline _ model =
    { model | stage = SA_ReceiveDecline } ! [ complete ]



--- When Leave is received (ignore RemoteMsg)


receiveLeave : JE.Value -> Model -> ( Model, Cmd RemoteMsg )
receiveLeave _ model =
    { model | stage = SA_ReceiveLeave } ! [ complete ]


receiveMessage : JE.Value -> Model -> ( Model, Cmd RemoteMsg )
receiveMessage raw model =
    receiveText raw model InChat



-- Decoders
-- On Details


detailsMsgDecoder : JD.Decoder DetailsMessage
detailsMsgDecoder =
    JD.map2 DetailsMessage
        (JD.field "name" JD.string)
        (JD.field "remote_id" JD.string)


acceptMsgDecoder : JD.Decoder DetailsMessage
acceptMsgDecoder =
    detailsMsgDecoder



-- On message / deny


textMsgDecoder : JD.Decoder TextMessage
textMsgDecoder =
    JD.map TextMessage
        (JD.field "body" JD.string)


denyMsgDecoder : JD.Decoder TextMessage
denyMsgDecoder =
    textMsgDecoder



{- Join -}


joinChannel : Model -> ( Model, Cmd RemoteMsg )
joinChannel model =
    case model.socket of
        Nothing ->
            model ! []

        Just modelSocket ->
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



-- General


reset : Val -> Model -> Val
reset val { turn } =
    (turn == Open) ? end 1 val =:= val


debounce : Ms -> Val -> Cmd RemoteMsg
debounce ms val =
    sleep (ms * millisecond)
        |> perform (always (RemoteTypeBounced val))



-- Complete


complete : Cmd RemoteMsg
complete =
    succeed RemoteComplete
        |> perform identity



-- subscriptions


subscriptions : Model -> Sub RemoteMsg
subscriptions model =
    case model.socket of
        Nothing ->
            Sub.none

        Just phxSocket ->
            Phoenix.Socket.listen phxSocket PhoenixMsg
