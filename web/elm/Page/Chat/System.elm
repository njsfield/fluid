module Page.Chat.System exposing (..)

import Data.Chat.System as I
import Model exposing (..)
import Util exposing (..)
import Time exposing (millisecond, every)
import Process exposing (sleep)
import Task exposing (perform)


type Msg
    = Internal_ I.Msg
    | SystemInput



-- System update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Internal_ internalMsg ->
            if internalMsg == I.Complete then
                update (SystemInput) { model | val = "" }
            else
                I.update internalMsg model
                    |> Tuple.mapSecond (Cmd.map Internal_)

        SystemInput ->
            let
                ( _, statement ) =
                    model.state
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


addInput : Val -> Val -> Val
addInput val statement =
    statement
        |> String.left ((+) 1 <| String.length val)



-- 2. Periodically send message to update


systemInput : Cmd Msg
systemInput =
    sleep (100 * millisecond)
        |> perform (always (SystemInput))
