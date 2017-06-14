module Main exposing (..)

import Navigation
import Update exposing (init, update, Msg(..), view)
import Model exposing (..)


-- MAIN


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
