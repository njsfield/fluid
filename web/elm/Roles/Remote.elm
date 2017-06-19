module Roles.Remote exposing (..)

import Types exposing (..)
import Util exposing (..)
import Task exposing (perform, succeed)
import Process exposing (sleep)
import Time exposing (millisecond)


-- Remote UPDATE


update : RemoteMsg -> Model -> ( Model, Cmd RemoteMsg )
update msg model =
    case msg of
        RemoteType str ->
            { model
                | turn = Remote
                , val = reset str model
            }
                ! [ debounce model.rest <| reset str model ]

        RemoteTypeBounced str ->
            model ! ((str == model.val) ? [ remoteFinishedTyping ] =:= [])

        _ ->
            model ! []


remoteFinishedTyping : Cmd RemoteMsg
remoteFinishedTyping =
    succeed RemoteFinishedTyping
        |> perform identity


reset : Val -> Model -> Val
reset val { turn } =
    (turn == Open) ? end 1 val =:= val


debounce : Ms -> Val -> Cmd RemoteMsg
debounce ms val =
    sleep (ms * millisecond)
        |> perform (always (RemoteTypeBounced val))
