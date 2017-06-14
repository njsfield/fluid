module Page.Chat.System exposing (..)

import Model exposing (..)
import Util exposing (..)
import Time exposing (millisecond, every)
import Process exposing (sleep)
import Task exposing (perform)


type Msg
    = Assess
    | SystemInput



-- System update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Assess ->
            (assess model)
                |> update (SystemInput)

        SystemInput ->
            let
                statement =
                    getStatement model.state
            in
                if model.val == statement then
                    { model | turn = Open } ! []
                else
                    { model | val = addInput model.val statement } ! [ systemInput ]



-- 1. Assess current model


assess : Model -> Model
assess model =
    let
        newState =
            case model.state of
                Initial _ ->
                    NamePrompt "Hi. Please type your name."

                NamePrompt _ ->
                    MakingRoom "Welcome. Let's make a room."

                MakingRoom _ ->
                    MakingRoom ""
    in
        { model
            | tachs = baseTachs
            , val = ""
            , turn = System
            , state = newState
        }



-- 2. Prepare statement from update state value


getStatement : State -> Val
getStatement state =
    case state of
        Initial val ->
            val

        NamePrompt val ->
            val

        MakingRoom val ->
            val



-- 3. Calculate difference of current val to target statement


addInput : Val -> Val -> Val
addInput val statement =
    statement
        |> String.left ((+) 1 <| String.length val)



-- 4. Periodically send message to update


systemInput : Cmd Msg
systemInput =
    sleep (100 * millisecond)
        |> perform (always (SystemInput))
