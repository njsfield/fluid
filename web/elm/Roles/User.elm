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
            if str == model.val then
                { model | turn = Open } ! completeIfReady model
            else
                model ! []

        _ ->
            model ! []



{- completeIfReady
   Only fire 'Complete'
   when user input ends with '.'
   AND state is NOT MakingRoom
-}


completeIfReady : Model -> List (Cmd Msg)
completeIfReady { val, state } =
    let
        isValid =
            isValidSystemReply val

        initState =
            case state of
                InChat ->
                    False

                _ ->
                    True
    in
        (isValid && initState) ? [ userFinishedTyping ] =:= []


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
