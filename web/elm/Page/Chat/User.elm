module Page.Chat.User exposing (..)

import Model exposing (..)
import Util exposing (..)
import Task exposing (perform, succeed)
import Process exposing (sleep)
import Time exposing (millisecond)


-- USER TACHS


tachs : Tachs
tachs =
    { baseTachs
        | restedBg = "bg-gray"
        , typingBg = "bg-blue"
        , typeCol = "white b--white"
        , restCol = "o-30"
        , emptyCol = "pl--black white b--black"
    }



-- USER MSG


type Msg
    = UserInput Val
    | UserInputBounced String
    | Complete



-- USER UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserInput str ->
            { model
                | tachs = tachs
                , turn = User
                , val = reset str model
            }
                ! [ debounce model.rest <| reset str model ]

        UserInputBounced str ->
            if str == model.val then
                { model | turn = Open } ! [ complete ]
            else
                model ! []

        _ ->
            model ! []


complete : Cmd Msg
complete =
    succeed Complete
        |> perform identity


reset : Val -> Model -> Val
reset val { turn } =
    (turn == Open) ? end 1 val =:= val


debounce : Ms -> Val -> Cmd Msg
debounce ms val =
    sleep (ms * millisecond)
        |> perform (always (UserInputBounced val))
