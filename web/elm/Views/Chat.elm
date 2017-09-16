module Views.Chat exposing (..)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, value, placeholder, style, autofocus)
import Html.Events exposing (onInput)
import Types exposing (..)
import Util exposing (..)


-- Tach/Tachs types


type alias Tach =
    String


type alias Tachs =
    { container : Tach
    , typingBg : Tach
    , input : Tach
    , typeCol : Tach
    , restCol : Tach
    , emptyCol : Tach
    }



-- All Tach models


baseTachs : Tachs
baseTachs =
    { container = "vw-100 vh-100 pa3 flex items-center justify-center smooth"
    , typingBg = "bg-lightest-blue"
    , input = "bt-0 br-0 bl-0 bw1 pa-1 lh-title w-100 mw6-ns bg-transparent outline-0 sans-serif smooth"
    , typeCol = "dark-gray b--dark-gray"
    , restCol = "0-30"
    , emptyCol = "pl--grey black b--black"
    }


userTachs : Tachs
userTachs =
    { baseTachs
        | typingBg = "bg-light-blue"
        , emptyCol = "pl--black white b--black"
    }


remoteTachs : Tachs
remoteTachs =
    { baseTachs
        | typingBg = "bg-light-green"
        , emptyCol = "pl--black white b--black"
    }


systemTachs : Tachs
systemTachs =
    { baseTachs
        | typingBg = "bg-moon-gray"
        , emptyCol = "pl--black white b--black"
    }



-- VIEW


view : Model -> Html UserMsg
view model =
    let
        tachs =
            setTachs model.turn
    in
        div [ class <| containerStyle model tachs ]
            [ input
                [ class <| inputStyle model tachs
                , placeholder model.placeholder
                , autofocus True
                , onInput UserType
                , value model.val
                ]
                []
            ]



-- INTERAL


setTachs : Role -> Tachs
setTachs turn =
    case turn of
        User ->
            userTachs

        Remote ->
            remoteTachs

        System ->
            systemTachs

        _ ->
            baseTachs


rest : Model -> Tachs -> Tach
rest { turn, val } tachs =
    (turn == Open && len val /= 0) ? tachs.restCol =:= ""


colour : Model -> Tachs -> Tach
colour { val } tachs =
    empty val ? tachs.emptyCol =:= tachs.typeCol


size : Model -> Tach
size { val, placeholder } =
    let
        min_len =
            (len val == 0) ? len placeholder =:= len val
    in
        min_len
            |> toFloat
            |> (\x -> (x - 1) / 54 * 4)
            |> ceiling
            |> clamp 1 9
            |> toString
            |> (++) "f"


inputStyle : Model -> Tachs -> Tach
inputStyle model tachs =
    [ rest model tachs
    , colour model tachs
    , size model
    , tachs.input
    ]
        |> String.join " "


containerStyle : Model -> Tachs -> Tach
containerStyle { turn } tachs =
    tachs.container ++ " " ++ tachs.typingBg
