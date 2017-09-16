module Test.Helpers exposing (..)

import Types exposing (..)


baseModel : Model
baseModel =
    { val = ""
    , rest = 0
    , name = ""
    , user_id = ""
    , channel_id = ""
    , remote_id = ""
    , remote_name = ""
    , turn = Open
    , placeholder = "Initialising..."
    , stage = ST_Introduction
    , socket = Nothing
    , socket_url = ""
    , entry = Creating
    }
