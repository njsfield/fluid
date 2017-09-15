module Types exposing (..)

import Navigation
import Json.Encode as JE
import Phoenix.Socket


-- Input Flags


type alias Flags =
    { user_id : String
    , socket_url : String
    }



-- Details Msg


type alias DetailsMessage =
    { name : String
    , remote_id : String
    }



-- Text Msg


type alias TextMessage =
    { body : String
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


type alias Subject =
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
    , remote_name : String
    , channel_id : String
    , rest : Ms
    , turn : Role
    , placeholder : String
    , stage : Stage
    , socket : Maybe (Phoenix.Socket.Socket RemoteMsg)
    , socket_url : String
    , entry : Entry
    }


type Entry
    = Joining
    | Creating



{- Stage
   Representing different stages in the application.
-}


type Stage
    = Begin
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
    | ST_SendRequest
    | SA_SendRequest
    | SA_ReceiveRequest
    | ST_ReceiveRequest
    | UT_UserResponse
    | SA_SendAccept
    | SA_SendDecline
    | SA_ReceiveAccept
    | ST_ReceiveAccept
    | SA_ReceiveDecline
    | ST_ReceiveDecline
    | SA_ReceiveLeave
    | ST_ReceiveLeave
    | Idle
    | InChat



-- Global Msg


type Msg
    = User_ UserMsg
    | System_ SystemMsg
    | Remote_ RemoteMsg
    | UrlChange Navigation.Location
    | SetUrl Url
    | Assess
    | LoadName (Maybe Val)
    | SaveName Val



-- System Msgs


type SystemMsg
    = SystemType
    | SystemFinishedTyping



-- User Msgs


type UserMsg
    = UserType Val
    | UserTypeBounced String
    | UserFinishedTyping



-- Remote Msg


type RemoteMsg
    = RemoteType Val
    | RemoteTypeBounced String
    | RemoteComplete
    | JoinChannel
    | JoinMessage String
    | SendRequest
    | SendAccept
    | SendDecline
    | SendMessage String
    | ReceiveRequest JE.Value
    | ReceiveAccept JE.Value
    | ReceiveDecline JE.Value
    | ReceiveLeave JE.Value
    | ReceiveMessage JE.Value
    | ConnectSocket
    | PhoenixMsg (Phoenix.Socket.Msg RemoteMsg)
