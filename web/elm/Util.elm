module Util exposing (..)

import Types exposing (..)
import Regex exposing (contains, regex)
import Task exposing (succeed, perform)


{- TERNARY
   (?) = Begin boolean check
   =:= = With either left or right argument
-}


(?) : Bool -> a -> Maybe a
(?) bool a =
    if bool then
        Just a
    else
        Nothing


infixl 1 ??


(=:=) : Maybe a -> a -> a
(=:=) =
    flip Maybe.withDefault
infixl 0 =:=



-- (^+) Reverse of ++


(^+) : appendable -> appendable -> appendable
(^+) x y =
    y ++ x
infixl 0 ^+



-- String helpers


len : Val -> Int
len =
    String.length


empty : Val -> Bool
empty val =
    len val == 0


end : Int -> String -> String
end =
    String.right



-- Validate a Users reply to system


isValidSystemReply : String -> Bool
isValidSystemReply val =
    val
        |> String.split " "
        |> List.head
        |> Maybe.withDefault ""
        |> contains (regex "[^\\s\\n]*\\.")


noStop : String -> String
noStop str =
    if (String.right 1 str == ".") then
        (noStop (String.dropRight 1 str))
    else
        str



-- Do (Msg to Cmd)


do : Msg -> Cmd Msg
do msg =
    succeed (msg)
        |> perform identity


firstIsY : String -> Bool
firstIsY str =
    String.left 1 str
        |> String.toUpper
        |> (==) "Y"
