module Roles.System exposing (..)

import Model exposing (..)
import Util exposing (..)
import Time exposing (millisecond, every)
import Process exposing (sleep)
import Task exposing (perform, attempt, succeed)
import Regex exposing (HowMany(All), replace, regex)
import Route exposing (setUrlWithUserID)
import Storage


-- System Msgs


type Msg
    = SystemType
    | SystemFinishedTyping


mapStateToStatement : State -> Name -> Statement
mapStateToStatement state name =
    case state of
        SystemType_Initialize ->
            "Initialising..."

        SystemType_Introduction ->
            "Hi there. Welcome to Fluid. Lets begin..."

        SystemType_NamePrompt ->
            "Please enter your first name, followed by a ."

        SystemType_Welcome ->
            "Welcome ##."
                |> replace All (regex "##") (\_ -> noStop name)

        SystemType_SetUrl ->
            "Your URL has just changed. Please share it with someone you'd like to chat with"

        SystemType_JoinChannel ->
            "I'm going to try to connect you now"

        _ ->
            ""



-- System update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SystemType ->
            -- Prepare Statement
            let
                statement =
                    mapStateToStatement model.state model.name
            in
                -- Check if input val is complete statement
                if model.val == statement then
                    -- If it is then set turn to open (for user to type)
                    -- Then send systemComplete
                    { model
                        | turn = Open
                        , placeholder = ""
                    }
                        ! [ systemFinishedTyping ]
                else
                    -- Otherwise add input
                    -- Call system input repeatedly
                    { model
                        | turn = System
                        , val = addInput model.val statement
                    }
                        -- Call systemType Interval cmd
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


systemType : Val -> Cmd Msg
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


systemFinishedTyping : Cmd Msg
systemFinishedTyping =
    sleep (1000 * millisecond)
        |> perform (always (SystemFinishedTyping))
