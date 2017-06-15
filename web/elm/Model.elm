module Model exposing (..)

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
    | SystemType_NamePrompt
    | UserType_Name
    | SystemAction_SaveName
    | SystemAction_LoadName
    | SystemType_Welcome
    | SystemType_Connect
    | InChat



-- MODEL


baseModel : Model
baseModel =
    { val = ""
    , rest = 1100
    , name = ""
    , turn = Open
    , placeholder = "Initialising..."
    , state = SystemType_Initialize
    , entry = Creating
    }
