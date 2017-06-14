module Route exposing (..)

import Navigation
import Model exposing (..)
import UrlParser exposing (..)


setEntryPoint : Navigation.Location -> Model -> Model
setEntryPoint location model =
    let
        parsedHash =
            parseHash (s "remote_id" </> string) location
    in
        case parsedHash of
            Just remote_id ->
                { model | entry = Joining remote_id }

            Nothing ->
                model
