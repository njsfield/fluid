module Model exposing (..)

-- Types


type alias Val =
    String


type alias Ms =
    Float


type alias Tach =
    String



-- Role


type Role
    = User
    | System
    | Remote
    | Open


type alias Tachs =
    { container : Tach
    , restedBg : Tach
    , typingBg : Tach
    , input : Tach
    , typeCol : Tach
    , restCol : Tach
    , emptyCol : Tach
    }


type alias Model =
    { val : Val
    , rest : Ms
    , turn : Role
    , placeholder : String
    , tachs : Tachs
    , state : ( State, Val )
    }



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



-- MODEL


baseModel : Model
baseModel =
    { val = ""
    , rest = 1100
    , turn = Open
    , placeholder = "Initialising..."
    , tachs = baseTachs
    , state = ( Initial, "Initialising" )
    }


baseTachs : Tachs
baseTachs =
    { container = "vw-100 vh-100 pa3 flex items-center justify-center smooth"
    , restedBg = "bg-green"
    , typingBg = "bg-green"
    , input = "bt-0 br-0 bl-0 bw1 pa-1 lh-title w-100 mw6-ns bg-transparent outline-0 sans-serif smooth"
    , typeCol = "white b--white"
    , restCol = ""
    , emptyCol = "pl--black black b--black"
    }
