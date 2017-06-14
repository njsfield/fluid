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
    = SystemInput
    | Assess
    | Complete
    | LoadName (Maybe Val)



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
        Initial ->
            statements.initial

        NamePrompt ->
            statements.namePrompt

        Welcome ->
            statements.welcome
                |> replace All (regex "##") (\_ -> String.dropRight 1 name)

        _ ->
            ""



-- System update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Assess ->
            assess model

        Complete ->
            { model | val = "" } ! [ systemInput ]

        LoadName maybeName ->
            case maybeName of
                Just name ->
                    { model | val = name, name = name, state = Welcome }
                        |> update (Assess)

                Nothing ->
                    update (Assess) model

        SystemInput ->
            let
                statement =
                    mapStateToStatement model.state model.name
            in
                if model.val == statement then
                    { model | turn = Open } ! []
                else
                    { model
                        | val = addInput model.val statement
                        , turn = System
                        , tachs = baseTachs
                    }
                        ! [ systemInput ]



-- 1. Calculate difference of current val to target statement


addInput : Val -> Statement -> Statement
addInput val statement =
    statement
        |> String.left ((+) 1 <| String.length val)



-- 2. Periodically send message to update


systemInput : Cmd Msg
systemInput =
    sleep (100 * millisecond)
        |> perform (always (SystemInput))



-- Storage Events (Cmds)


getNameFromStorage : Cmd Msg
getNameFromStorage =
    Storage.get "name"
        |> attempt
            (\res ->
                case res of
                    Ok name ->
                        LoadName name

                    Err _ ->
                        LoadName Nothing
            )


saveNameToStorage : Name -> Cmd Msg
saveNameToStorage name =
    Storage.set "name" name
        |> attempt (always Assess)



-- Final complete Cmd


complete : Cmd Msg
complete =
    succeed Complete
        |> perform identity



{-
   1. assess
-}


assess : Model -> ( Model, Cmd Msg )
assess model =
    case model.state of
        Initial ->
            { model | state = NamePrompt } ! [ complete ]

        NamePrompt ->
            { model | state = Welcome } ! [ saveNameToStorage model.val ]

        Welcome ->
            { model | name = model.val, state = Welcome } ! [ complete ]

        _ ->
            model ! []
