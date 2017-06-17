module Model exposing (..)

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



-- MODEL


baseModel : Model
baseModel =
    { val = ""
    , rest = 1100
    , name = ""
    , user_id = ""
    , turn = Open
    , placeholder = "Initialising..."
    , state = SystemType_Initialize
    , entry = Creating
    }
