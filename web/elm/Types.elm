module Types exposing (..)

import Navigation


-- Input Flags


type alias Flags =
    { user_id : String
    }



-- Types


type alias Val =
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
    , rest : Ms
    , turn : Role
    , placeholder : String
    , state : State
    , entry : Entry
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
    | SystemAction_JoinChannel
    | SystemType_JoinChannel
    | InChat



-- Types


type Msg
    = User_ UserMsg
    | System_ SystemMsg
    | UrlChange Navigation.Location
    | Assess
    | SendMsg Val
    | LoadName (Maybe Val)



-- System Msgs


type SystemMsg
    = SystemType
    | SystemFinishedTyping



-- User Msgs


type UserMsg
    = UserType Val
    | UserTypeBounced String
    | UserFinishedTyping
