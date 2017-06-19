module Assess exposing (..)

import Types exposing (..)
import Util exposing (..)
import Task exposing (succeed, perform, attempt)
import Storage
import Route exposing (setEntryPoint, setUrlWithUserID)


{-
    (From Types)

   type State
       = SystemType_Initialize
       | SystemType_Introduction
       | SystemType_NamePrompt
       | UserType_Name
       | SystemAction_SaveName
       | SystemAction_LoadName
       | SystemType_Welcome
       | SystemType_Connect
       | SystemAction_SetUrl
       | SystemType_SetUrl
       | SystemType_ConnectSocket
       | SystemAction_ConnectSocket
       | SystemAction_JoinChannel
       | User_Idle
       | InChat

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
                ? ({ model | state = SystemAction_SaveName } ! [ saveName (noStop model.val) ])
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
                { model | val = "", state = SystemAction_SetUrl } ! [ setUrl model.user_id ]
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


setUrl : Url -> Cmd Msg
setUrl url =
    do (SetUrl url)
