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
   Representing different states in the application
   Should used in a Tuple in the model alongside
   a String representating the system Prompt
   depending on the state.
-}


type State
    = Initial
    | NamePrompt
    | Welcome
    | Connecting
    | Idle
    | Requesting
    | InChat



-- MODEL


baseModel : Model
baseModel =
    { val = ""
    , rest = 1100
    , name = ""
    , turn = Open
    , placeholder = "Initialising..."
    , state = Initial
    , entry = Creating
    }
