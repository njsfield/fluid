module Views.Chat exposing (view)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, value, placeholder, style, autofocus)
import Html.Events exposing (onInput)
import Page.Chat.User exposing (..)
import Model exposing (..)
import Util exposing (..)


-- VIEW


view : Model -> Html Msg
view model =
    div [ class <| containerStyle model ]
        [ input
            [ class <| inputStyle model
            , placeholder model.placeholder
            , autofocus True
            , onInput UserInput
            , value model.val
            ]
            []
        ]



-- INTERAL


rest : Model -> Tach
rest { turn, val, tachs } =
    (turn == Open && len val /= 0) ? tachs.restCol =:= ""


colour : Model -> Tach
colour { val, tachs } =
    empty val ? tachs.emptyCol =:= tachs.typeCol


size : Model -> Tach
size { val } =
    len val
        |> toFloat
        |> (\x -> (x - 1) / 54 * 4)
        |> ceiling
        |> clamp 1 9
        |> toString
        |> (++) "f"


inputStyle : Model -> Tach
inputStyle model =
    [ rest model
    , colour model
    , size model
    , model.tachs.input
    ]
        |> String.join " "


containerStyle : Model -> Tach
containerStyle { tachs, turn } =
    tachs.container ++ " " ++ ((turn == Open) ? tachs.restedBg =:= tachs.typingBg)
