module Util exposing (..)

import Model exposing (..)
import Regex exposing (contains, regex)


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
(=:=) l r =
    case l of
        Just l ->
            l

        _ ->
            r
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
        |> contains (regex "\\w\\.")


noStop : String -> String
noStop str =
    (String.right 1 str == ".") ? (String.dropRight 1 str) =:= str
