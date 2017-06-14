module Data.Chat.System exposing (..)

import Model exposing (..)
import Task exposing (attempt, succeed, perform)
import Regex exposing (HowMany(All), replace, regex)
import Storage


{- INTERNAL

   Lowest level executions.
   higher update functions may call the
   Assess message to determine next
   logical state of application

-}
-- System statements


type alias Statement =
    String


states =
    { initial = ( Initial, "Initialising..." )
    , namePrompt = ( NamePrompt, "Please enter your first name, followed by a ." )
    , loadedFromStorage = ( Welcome, "Welcome, I will now load your name" )
    , savingToStorage = ( Welcome, "Welcome, I will now save your name" )
    , welcome = ( Welcome, "Welcome ##. Lets make a room..." )
    }


type Msg
    = Assess
    | Complete
    | LoadName (Maybe Val)



{- Internal update
   Perform assessmets of current state/model
   Interact with local storage
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    if msg == Complete then
        { model | val = "" } ! [ complete ]
    else
        case msg of
            Assess ->
                assess model

            LoadName maybeName ->
                case maybeName of
                    Just name ->
                        { model
                            | val = name
                            , state = states.loadedFromStorage
                        }
                            |> update (Assess)

                    Nothing ->
                        update (Assess) model

            _ ->
                model ! []



-- Storage Events (Cmds)


getNameFromStorage : Cmd Msg
getNameFromStorage =
    Storage.get "name"
        |> attempt
            (\res ->
                case res of
                    Ok name ->
                        LoadName name

                    Err _ ->
                        LoadName Nothing
            )


saveNameToStorage : Val -> Cmd Msg
saveNameToStorage name =
    Storage.set "name" name
        |> attempt (always Assess)



-- Final complete Cmd


complete : Cmd Msg
complete =
    succeed Complete
        |> perform identity



-- assess


assess : Model -> ( Model, Cmd Msg )
assess model =
    case model.state of
        ( Initial, _ ) ->
            { model | state = states.namePrompt } ! [ complete ]

        ( NamePrompt, _ ) ->
            { model | state = states.savingToStorage } ! [ saveNameToStorage model.val ]

        ( Welcome, _ ) ->
            { model | state = mixName model.val states.welcome } ! [ complete ]



-- Replace "##" in a statement with Name, return state tuple


mixName : Val -> ( State, Val ) -> ( State, Val )
mixName name ( state, statement ) =
    ( state, statement )
        |> Tuple.mapSecond (replace All (regex "##") (\_ -> String.dropRight 1 name))
