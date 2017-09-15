module Roles.System exposing (..)

import Types exposing (..)
import Util exposing (..)
import Time exposing (millisecond, every)
import Process exposing (sleep)
import Task exposing (perform, attempt, succeed)
import Regex exposing (HowMany(All), replace, regex)
import Storage


-- Map statements helper


mapStageToStatement : Stage -> Model -> Statement
mapStageToStatement stage { name, remote_name } =
    case stage of
        ST_NamePrompt ->
            "Hi there. Please enter your first name, followed by a ."

        ST_Welcome ->
            "Welcome ##."
                |> replaceHashes name

        ST_ConnectSocket ->
            "Connecting"

        ST_ReceiveRequest ->
            "## would like to chat. Allow? [Y/n]"
                |> replaceHashes remote_name

        ST_ReceiveAccept ->
            "## has accepted! Now in chat"
                |> replaceHashes remote_name

        ST_ReceiveDecline ->
            "Unable to connect."

        ST_ReceiveLeave ->
            "## has left."
                |> replaceHashes remote_name

        _ ->
            ""


replaceHashes : Name -> String -> String
replaceHashes name string =
    replace All (regex "##") (\_ -> name) string



-- System update


update : SystemMsg -> Model -> ( Model, Cmd SystemMsg )
update msg model =
    case msg of
        SystemType ->
            -- Prepare Statement
            let
                statement =
                    mapStageToStatement model.stage model
            in
                -- Check if input val is complete statement
                if model.val == statement then
                    -- If it is then set turn to open (for user to type)
                    -- Then send systemComplete
                    { model
                        | turn = Open
                        , placeholder = statement
                    }
                        ! [ systemFinishedTyping ]
                else
                    -- Otherwise add input
                    -- Call system input repeatedly
                    { model
                        | turn = System
                        , val = addInput model.val statement
                    }
                        -- Call ST Interval cmd
                        -- Pass last character of val to determine speed
                        !
                            [ systemType <| String.right 1 model.val ]

        _ ->
            model ! []



-- 1. Calculate difference of current val to target statement


addInput : Val -> Statement -> Statement
addInput val statement =
    statement
        |> String.left ((+) 1 <| String.length val)



-- 2. Periodically send message to update


systemType : Val -> Cmd SystemMsg
systemType end =
    let
        pace =
            case end of
                -- Slowest if full stop
                "." ->
                    900

                -- Slower if comma
                "," ->
                    500

                -- Regular speed
                _ ->
                    100
    in
        sleep (pace * millisecond)
            |> perform (always (SystemType))



-- System finished typing statement,
-- Send Complete Msg (after short delay)


systemFinishedTyping : Cmd SystemMsg
systemFinishedTyping =
    sleep (1000 * millisecond)
        |> perform (always (SystemFinishedTyping))
