module Roles.User exposing (..)

import Model exposing (..)
import Util exposing (..)
import Task exposing (perform, succeed)
import Process exposing (sleep)
import Time exposing (millisecond)


-- USER MSG


type Msg
    = UserType Val
    | UserTypeBounced String
    | UserFinishedTyping



-- USER UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserType str ->
            { model
                | turn = User
                , val = reset str model
            }
                ! [ debounce model.rest <| reset str model ]

        UserTypeBounced str ->
            model ! ((str == model.val) ? [ userFinishedTyping ] =:= [])

        _ ->
            model ! []


userFinishedTyping : Cmd Msg
userFinishedTyping =
    succeed UserFinishedTyping
        |> perform identity


reset : Val -> Model -> Val
reset val { turn } =
    (turn == Open) ? end 1 val =:= val


debounce : Ms -> Val -> Cmd Msg
debounce ms val =
    sleep (ms * millisecond)
        |> perform (always (UserTypeBounced val))
