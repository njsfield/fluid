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
{- Model Helpers
   For general purpose model changes
-}
-- withStage: Simply Adds Stage to model


setStage : Model -> Stage -> Model
setStage model stage =
    { model
        | stage = stage
    }


setStageNoVal : Model -> Stage -> Model
setStageNoVal model stage =
    { model
        | val = ""
        , stage = stage
    }


setStageAndName : Model -> Stage -> Model
setStageAndName model stage =
    { model
        | name = (noStop model.val)
        , stage = stage
    }


setStageAndNameNoVal : Model -> Stage -> Model
setStageAndNameNoVal model stage =
    { model
        | val = ""
        , name = (noStop model.val)
        , stage = stage
    }


setPlaceholderNoVal : Model -> Stage -> String -> Model
setPlaceholderNoVal model stage placeholder =
    { model
        | val = ""
        , placeholder = placeholder
        , turn = Open
        , stage = stage
    }


setPlaceholder : Model -> Stage -> String -> Model
setPlaceholder model stage placeholder =
    { model
        | placeholder = placeholder
        , turn = Open
        , stage = stage
    }


fullReset : Model -> Stage -> Model
fullReset model stage =
    { model
        | val = ""
        , placeholder = ""
        , remote_name = ""
        , remote_id = ""
    }



-- Placeholder Model


chatPlaceholder : Model -> Model
chatPlaceholder model =
    setPlaceholderNoVal model InChat ("Now chatting with " ++ model.name)


sharePlaceholder : Model -> Model
sharePlaceholder model =
    let
        new_model =
            setPlaceholderNoVal model Idle "Please share this URL"
    in
        { new_model | entry = Creating }


requestPlaceholder : Model -> Model
requestPlaceholder model =
    setPlaceholderNoVal model Idle "Sending request to remote..."



-- In Chat


inChat : Model -> Model
inChat model =
    setPlaceholder model InChat model.placeholder



-- Main Assess


assess : Model -> ( Model, Cmd Msg )
assess model =
    -- First check stage
    case model.stage of
        -- 1. Begin with introduction
        Begin ->
            setStage model ST_Introduction ! [ sysInput ]

        -- 2. System type introduction
        ST_Introduction ->
            setStageNoVal model ST_NamePrompt ! [ sysInput ]

        -- 3. After system asked for name
        ST_NamePrompt ->
            setStageNoVal model UT_Name ! []

        -- 4. After user has typed name (if valid) then send name
        UT_Name ->
            (isValidSystemReply model.val)
                ? (setStage model SA_SaveName ! [ saveName (noStop model.val) ])
                =:= (model ! [])

        -- 5 (a). System should type Welcome after saving
        SA_SaveName ->
            setStageAndNameNoVal model ST_Welcome ! [ sysInput ]

        -- 6 (b). System should type Welcome after loading
        SA_LoadName ->
            setStageAndName model ST_Welcome ! [ sysInput ]

        -- 7. After welcome, set Url (if creating)
        ST_Welcome ->
            (model.entry == Creating)
                ? (setStageNoVal model SA_SetUrl ! [ setUrl model.user_id ])
                =:= (setStageNoVal model ST_ConnectSocket ! [ sysInput ])

        -- 8 (a.1) After setting URL
        SA_SetUrl ->
            setStage model ST_ConnectSocket ! [ sysInput ]

        -- 9. Perform Connect
        ST_ConnectSocket ->
            setStage model SA_ConnectSocket ! [ connectSocket ]

        -- 10. Perform Join
        SA_ConnectSocket ->
            setStage model SA_JoinChannel ! [ joinChannel ]

        -- 11. After Join
        SA_JoinChannel ->
            (model.entry == Creating)
                ? (sharePlaceholder model ! [])
                =:= (requestPlaceholder model ! [ sendRequest ])

        -- 12.a User Receives Request
        SA_ReceiveRequest ->
            setStage model ST_ReceiveRequest ! [ sysInput ]

        -- 13. After system typed info for user
        ST_ReceiveRequest ->
            setStageNoVal model UT_UserResponse ! []

        -- 14. After User responds
        UT_UserResponse ->
            -- Have they typed Yes?
            (firstIsY model.val)
                ? (chatPlaceholder model ! [ sendAccept ])
                =:= (sharePlaceholder model ! [ sendDecline ])

        -- 15.a After receiving accept
        SA_ReceiveAccept ->
            setStageNoVal model ST_ReceiveAccept ! [ sysInput ]

        -- 16a. After typing receive accept
        ST_ReceiveAccept ->
            chatPlaceholder model ! []

        -- 15.b After receiving decline
        SA_ReceiveDecline ->
            setStageNoVal model ST_ReceiveDecline ! [ sysInput ]

        -- 16.b Reset back to set URL
        ST_ReceiveDecline ->
            sharePlaceholder model ! [ setUrl model.user_id ]

        -- 17 After receiving leave
        SA_ReceiveLeave ->
            setStageNoVal model ST_ReceiveLeave ! [ sysInput ]

        -- 18 After typing leave
        ST_ReceiveLeave ->
            fullReset model SA_SetUrl ! [ setUrl model.user_id ]

        InChat ->
            inChat model ! []

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
