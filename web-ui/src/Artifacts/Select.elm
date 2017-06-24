module Artifacts.Select exposing (..)

-- module to define `select` elements

import Dict
import Set
import Html exposing (..)
import Html.Attributes exposing (value, class, href, title, id, selected)
import Html.Events exposing (onClick, onInput)
import Styles exposing (warning)
import Messages exposing (AppMsg(..), Route(..))
import Models exposing (Model, getArtifact, memberArtifact, getDefs)
import Utils
    exposing
        ( isJust
        , assertOr
        , enumerate
        , memberIndexUnsafe
        , setIndexUnsafe
        , popIndexUnsafe
        )
import Artifacts.Models
    exposing
        ( Artifact
        , Name
        , Type(..)
        , EditableArtifact
        , indexName
        , indexNameUnchecked
        , initNameUnsafe
        , initName
        , getType
        , autoPartof
        , validPartof
        )
import Artifacts.Messages exposing (Msg(..))
import Artifacts.View as View


-- Notes: How to create custom events
--
--    import Html.Events exposing (on, targetValue)
--    import Json.Decode as Json
--    on "change" (Json.map selectMsg targetValue)
-- PARTOF ELEMENT


{-| view or edit the partof fields
-}
partof : Model -> Artifact -> Maybe EditableArtifact -> Html AppMsg
partof model artifact edited =
    let
        values =
            case edited of
                Just a ->
                    a.partof

                Nothing ->
                    artifact.partof

        ( addPartof, getItem ) =
            case edited of
                Just e ->
                    editPartofComponents model artifact e

                Nothing ->
                    let
                        poItem ( _, name ) =
                            li
                                [ class "underline" ]
                                [ View.seeArtifactName model name artifact "partof" False ]

                        createPo =
                            []
                    in
                        ( createPo, poItem )
    in
        ul
            [ View.getId "partof" artifact Nothing ]
            ((List.map getItem (enumerate values))
                ++ addPartof
            )


{-| return components necessary for editing partof

returns:

  - addPartof: a list containing the dropdown for creating new partof pieces
  - getItem: given a (index, name) it has the logic for selecting (editing) a
    partof item

-}
editPartofComponents :
    Model
    -> Artifact
    -> EditableArtifact
    -> ( List (Html AppMsg), ( Int, Name ) -> Html AppMsg )
editPartofComponents model artifact edited =
    let
        -- return names that this name could be a partof
        validPartofs model name =
            let
                names =
                    List.map (\a -> a.name) (Dict.values model.artifacts)

                out =
                    List.filter (\n -> validPartof name n) names
            in
                List.sortBy (\n -> n.value) out

        -- FIXME: need to use edited.name
        valid =
            validPartofs model artifact.name

        getItem ( index, name ) =
            li
                []
                (partofItem model valid artifact edited index name)

        emptyName : Name
        emptyName =
            { raw = "---"
            , value = "---"
            , ty = Req
            }

        createMsg rawName =
            if rawName == emptyName.value then
                Noop
            else
                let
                    partof =
                        List.sortBy (\n -> n.value) <|
                            edited.partof
                                ++ [ initNameUnsafe rawName ]
                in
                    ArtifactsMsg
                        (EditArtifact
                            artifact.id
                            { edited | partof = partof }
                        )

        -- you can only add elements that aren't already present
        partof_exist =
            Set.fromList <| List.map (\n -> n.value) edited.partof

        create_valid =
            List.filter (\n -> not <| Set.member n.value partof_exist) valid

        add_partof =
            [ i [ class "fa fa-plus-square mr1 olive", title "add partof" ] []
            , selectPartof
                model
                ([ emptyName ] ++ create_valid)
                emptyName
                ("add_partof_" ++ artifact.name.value)
                createMsg
            ]
    in
        ( add_partof, getItem )


{-| return the full html element of a partof item

This includes buisness logic for:

  - deleting the item
  - changing the item's value to valid names ONLY

In addition, it also handles the following cases:

  - if the item was created automatically, it is read-only
  - if the item is invalid, it is delete-only (not editable)

-}
partofItem :
    Model
    -> List Name
    -> Artifact
    -> EditableArtifact
    -> Int
    -> Name
    -> List (Html AppMsg)
partofItem model valid_partofs artifact edited index name =
    let
        part_id =
            artifact.name.value ++ "_" ++ name.value

        deleteMsg =
            let
                partof =
                    Tuple.second <| popIndexUnsafe index edited.partof
            in
                ArtifactsMsg <| EditArtifact artifact.id { edited | partof = partof }

        deleteBtn =
            button
                [ class "btn bold red"
                , id <| "delete_partof_" ++ part_id
                , onClick deleteMsg
                , title "delete"
                ]
                [ i [ class "fa fa-trash" ] [] ]

        updateMsg rawName =
            let
                updateName =
                    initNameUnsafe rawName

                partof =
                    List.sortBy (\n -> n.value) <|
                        setIndexUnsafe index updateName edited.partof
            in
                ArtifactsMsg
                    (EditArtifact
                        artifact.id
                        { edited | partof = partof }
                    )

        see_art =
            View.seeArtifactName model name artifact "partof" True
    in
        case checkPartof model edited.name name of
            Err error ->
                -- it is invalid. Only allow deletion
                [ deleteBtn
                , see_art
                , warning error
                ]

            Ok ed_name ->
                if autoPartof ed_name name then
                    -- it was created automatically and CANNOT be edited
                    [ button
                        [ class "btn bold"
                        , title "created automatically"
                        ]
                        [ i [ class "fa fa-info" ] [] ]
                    , see_art
                    ]
                else
                    -- it is editable
                    let
                        -- cannot set to other partofs that exist
                        -- or to own current/future name
                        partof_exist =
                            Set.remove name.value <|
                                Set.union (Set.fromList [ ed_name.value, artifact.name.value ]) <|
                                    Set.fromList (List.map (\n -> n.value) edited.partof)

                        valid =
                            List.filter
                                (\n ->
                                    not <|
                                        Set.member n.value partof_exist
                                )
                                valid_partofs
                    in
                        [ deleteBtn
                        , see_art
                        , selectPartof model valid name ("select_partof_" ++ part_id) updateMsg
                        ]


{-| the select html element
-}
selectPartof :
    Model
    -> List Name
    -> Name
    -> String
    -> (String -> AppMsg)
    -> Html AppMsg
selectPartof model valid_partofs name id_ selectMsg =
    select
        [ class "select-tiny"
        , id id_
        , onInput selectMsg
        ]
        (List.map
            (\n ->
                option
                    [ id <| "select_option_" ++ name.value ++ "_" ++ n.value
                    , value n.raw
                    , selected (n == name)
                    ]
                    [ text <| "  " ++ n.raw ]
            )
            valid_partofs
        )


{-| return some error if the name cannot be a partof `partof`
(i.e. if `partof` cannot be in name's partof attrs)

Possible errors:

  - name is invalid
  - partof does not exist
  - partof/name are invalid types

Otherwise return the valid name

-}
checkPartof : Model -> String -> Name -> Result String Name
checkPartof model name partof =
    case initName name of
        Ok name ->
            if not <| memberArtifact partof.value model then
                Err "does not exist"
            else if not <| validPartof name partof then
                Err "invalid type"
            else
                Ok name

        Err _ ->
            Err "invalid artifact name"



-- DEFINED ELEMENT


{-| shows the location where the artifact is defined
(which toml file it is written in)
-}
defined : Model -> Artifact -> Maybe EditableArtifact -> Html AppMsg
defined model artifact edited =
    case edited of
        Just e ->
            editDefined model artifact e

        Nothing ->
            div
                [ View.getId "def" artifact Nothing
                ]
                [ span [ class "bold" ] [ text "Defined at: " ]
                , text artifact.def
                ]


editDefined : Model -> Artifact -> EditableArtifact -> Html AppMsg
editDefined model artifact edited =
    let
        selectMsg def =
            ArtifactsMsg <| EditArtifact artifact.id { edited | def = def }
    in
        div []
            [ span [ class "bold" ] [ text edited.def ]
            , select
                [ class "select-tiny"
                , View.getId "def" artifact (Just edited)
                , onInput selectMsg
                ]
                (List.map
                    (\d ->
                        option
                            [ value d
                            , selected (d == edited.def)
                            ]
                            [ text <| "  " ++ d ]
                    )
                    (getDefs model)
                )
            ]