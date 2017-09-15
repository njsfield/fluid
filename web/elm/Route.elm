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
                { model
                    | remote_id = remote_id
                    , entry = Joining
                }

            Nothing ->
                model



-- Makes Cmd to modify URL with Hash of user_id


buildUrl : String -> String
buildUrl user_id =
    "/#"
        ++ urlHash
        ++ "/"
        ++ user_id


setUrlWithUserId : String -> Cmd Msg
setUrlWithUserId =
    buildUrl >> Navigation.modifyUrl
