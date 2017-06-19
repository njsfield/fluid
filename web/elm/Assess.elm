module Assess exposing (assess)

import Types exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform, attempt)
import Storage
import Route exposing (setEntryPoint, setUrlWithUserId)


{-
    (From Types)

   type Stage
       = ST_Initialize
       | ST_Introduction
       | ST_NamePrompt
       | UT_Name
       | SA_SaveName
       | SA_LoadName
       | ST_Welcome
       | ST_Connect
       | SA_SetUrl
       | ST_SetUrl
       | ST_ConnectSocket
       | SA_ConnectSocket
       | SA_JoinChannel
       | User_Idle
       | InChat

      Main Assess
      Toggles through next stage
      depending on stage
-}


assess : Model -> ( Model, Cmd Msg )
assess model =
    -- First check stage
    case model.stage of
        -- 1. Begin with introduction
        Begin ->
            { model | stage = ST_Introduction } ! [ sysInput ]

        -- 2. System type introduction
        ST_Introduction ->
            { model | val = "", stage = ST_NamePrompt } ! [ sysInput ]

        -- 3. After system asked for name
        ST_NamePrompt ->
            { model | val = "", stage = UT_Name } ! []

        -- 4. After user has typed name (if valid) then send name
        UT_Name ->
            (isValidSystemReply model.val)
                ? ({ model | stage = SA_SaveName } ! [ saveName (noStop model.val) ])
                =:= (model ! [])

        -- 5 (a). System should type Welcome after saving
        SA_SaveName ->
            { model | val = "", name = (noStop model.val), stage = ST_Welcome } ! [ sysInput ]

        -- 6 (b). System should type Welcome after loading
        SA_LoadName ->
            { model | name = model.val, stage = ST_Welcome } ! [ sysInput ]

        -- 7. After welcome, set Url (if creating)
        ST_Welcome ->
            if (model.entry == Creating) then
                { model | val = "", stage = SA_SetUrl } ! [ setUrl model.user_id ]
            else
                { model | val = "", stage = ST_ConnectSocket } ! [ sysInput ]

        -- 8 (a.1) After setting URL
        SA_SetUrl ->
            { model | stage = ST_ConnectSocket } ! [ sysInput ]

        -- 9. Perform Connect
        ST_ConnectSocket ->
            { model | stage = SA_ConnectSocket } ! [ connectSocket ]

        -- 10. Perform Join
        SA_ConnectSocket ->
            { model | stage = SA_JoinChannel } ! [ joinChannel ]

        -- 11. After Join
        SA_JoinChannel ->
            if (model.entry == Creating) then
                -- Display Share URL
                { model | val = "", placeholder = "Please share this URL", stage = Idle } ! []
            else
                -- Display Send Request
                { model | val = "", placeholder = "Sending request to remote", stage = Idle } ! [ sendRequest ]

        -- 12.a User Receives Request
        SA_ReceiveRequest ->
            { model | stage = ST_ReceiveRequest } ! [ sysInput ]

        -- 13. After system typed info for user
        ST_ReceiveRequest ->
            { model | val = "", stage = UT_UserResponse } ! []

        -- 14. After User responds
        UT_UserResponse ->
            case (String.left 1 model.val |> String.toUpper) of
                "Y" ->
                    { model | val = "", stage = SA_SendAccept } ! [ sendAccept ]

                _ ->
                    { model
                        | val = ""
                        , stage = SA_SendDecline
                        , remote_id = ""
                        , remote_name = ""
                    }
                        ! [ sendDecline ]

        -- 15.a After receiving accept
        SA_ReceiveAccept ->
            { model | val = "", stage = ST_ReceiveAccept } ! [ sysInput ]

        -- 16a. After typing receive accept
        ST_ReceiveAccept ->
            { model
                | val = ""
                , placeholder = ("You are now chatting with " ++ model.remote_name)
                , stage = InChat
            }
                ! []

        -- 15.b After receiving decline
        SA_ReceiveDecline ->
            { model | val = "", stage = ST_ReceiveDecline } ! [ sysInput ]

        -- 16.b Reset back to set URL
        ST_ReceiveDecline ->
            { model
                | val = ""
                , placeholder = ""
                , remote_id = ""
                , stage = SA_SetUrl
            }
                ! [ setUrl model.user_id ]

        -- 17 After receiving leave
        SA_ReceiveLeave ->
            { model | val = "", stage = ST_ReceiveLeave } ! [ sysInput ]

        -- 18 After typing leave
        ST_ReceiveLeave ->
            { model
                | val = ""
                , placeholder = ""
                , remote_id = ""
                , stage = SA_SetUrl
            }
                ! [ setUrl model.user_id ]

        _ ->
            model ! []



-- Do helpers (Route back to update)


sysInput : Cmd Msg
sysInput =
    do (System_ SystemType)


connectSocket : Cmd Msg
connectSocket =
    do (ConnectSocket)


joinChannel : Cmd Msg
joinChannel =
    do (JoinChannel)


saveName : Name -> Cmd Msg
saveName name =
    do (SaveName name)


sendRequest : Cmd Msg
sendRequest =
    do (SendRequest)


sendAccept : Cmd Msg
sendAccept =
    do (SendAccept)


sendDecline : Cmd Msg
sendDecline =
    do (SendDecline)


setUrl : Url -> Cmd Msg
setUrl url =
    do (SetUrl url)
