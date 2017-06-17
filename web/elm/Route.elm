module Route exposing (..)

import Navigation
import Types exposing (..)
import UrlParser exposing (..)


urlHash : Id
urlHash =
    "remote_id"


setEntryPoint : Navigation.Location -> Model -> Model
setEntryPoint location model =
    let
        parsedHash =
            parseHash (s urlHash </> string) location
    in
        case parsedHash of
            Just remote_id ->
                { model | entry = Joining remote_id }

            Nothing ->
                model


setUrlWithUserID : String -> Cmd msg
setUrlWithUserID user_id =
    "/#"
        ++ urlHash
        ++ "/"
        ++ user_id
        |> Navigation.modifyUrl
