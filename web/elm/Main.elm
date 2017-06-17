module Main exposing (..)

import Navigation
import Update exposing (init, update, Msg(..), view)
import Model exposing (..)


-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
