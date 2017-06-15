module Roles.System exposing (..)

import Model exposing (..)
import Util exposing (..)
import Time exposing (millisecond, every)
import Process exposing (sleep)
import Task exposing (perform, attempt, succeed)
import Regex exposing (HowMany(All), replace, regex)
import Route exposing (setUrlWithUserID)
import Storage


-- System Msgs


type Msg
    = SystemType
    | SystemFinishedTyping



{- MAP STATEMENTS TO STATE -}


statements =
    { initial = "Initialising..."
    , namePrompt = "Please enter your first name, followed by a ."
    , loadedFromStorage = "Welcome, I will now load your name"
    , savingToStorage = "Welcome, I will now save your name"
    , welcome = "Welcome ##. Lets make a room..."
    }


mapStateToStatement : State -> Name -> Statement
mapStateToStatement state name =
    case state of
        SystemType_Initialize ->
            statements.initial

        SystemType_NamePrompt ->
            statements.namePrompt

        SystemType_Welcome ->
            statements.welcome
                |> replace All (regex "##") (\_ -> noStop name)

        _ ->
            ""



-- System update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SystemType ->
            -- Prepare Statement
            let
                statement =
                    mapStateToStatement model.state model.name
            in
                -- Check if input val is complete statement
                if model.val == statement then
                    -- If it is then set turn to open (for user to type)
                    -- Then send systemComplete
                    { model
                        | turn = Open
                        , placeholder = ""
                    }
                        ! [ systemFinishedTyping ]
                else
                    -- Otherwise add input
                    -- Call system input repeatedly
                    { model
                        | turn = System
                        , val = addInput model.val statement
                    }
                        ! [ systemType ]

        _ ->
            model ! []



-- 1. Calculate difference of current val to target statement


addInput : Val -> Statement -> Statement
addInput val statement =
    statement
        |> String.left ((+) 1 <| String.length val)



-- 2. Periodically send message to update


systemType : Cmd Msg
systemType =
    sleep (100 * millisecond)
        |> perform (always (SystemType))



-- System finished typing statement,
-- Send Complete Msg (after short delay)


systemFinishedTyping : Cmd Msg
systemFinishedTyping =
    sleep (1000 * millisecond)
        |> perform (always (SystemFinishedTyping))
