module Types exposing (..)

import Navigation
import Json.Encode as JE
import Phoenix.Socket


-- Input Flags


type alias Flags =
    { user_id : String
    , socket_url : String
    }



-- Types


type alias Val =
    String


type alias Url =
    String


type alias Ms =
    Float


type alias Id =
    String


type alias Name =
    String


type alias Statement =
    String



-- Role


type Role
    = User
    | System
    | Remote
    | Open



-- GLOBAL MODEL


type alias Model =
    { val : Val
    , name : Name
    , user_id : String
    , remote_id : String
    , rest : Ms
    , turn : Role
    , placeholder : String
    , state : State
    , socket : Maybe (Phoenix.Socket.Socket Msg)
    , socket_url : String
    }


type Entry
    = Joining String
    | Creating



{- State
   Representing different states in the application.
-}


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



-- Global Msg


type Msg
    = User_ UserMsg
    | System_ SystemMsg
    | UrlChange Navigation.Location
    | Assess
    | SendMsg Val
    | LoadName (Maybe Val)
    | JoinChannel
    | ReceiveMessage JE.Value
    | ConnectSocket
    | PhoenixMsg (Phoenix.Socket.Msg Msg)



-- System Msgs


type SystemMsg
    = SystemType
    | SystemFinishedTyping



-- User Msgs


type UserMsg
    = UserType Val
    | UserTypeBounced String
    | UserFinishedTyping
