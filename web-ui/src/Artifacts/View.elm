module Artifacts.View exposing (..)
{-
Generic view methods that can be used in multiple places (List, Edit, etc)
-}

import String
import Html exposing (..)
import Html.Attributes exposing (class, href, title, id)
import Html.Events exposing (onClick)

import Messages exposing (AppMsg(..), Route(..))
import Models exposing (Model)
import Artifacts.Models exposing (Artifact, artifactNameUrl, indexName, indexNameUnchecked)
import Artifacts.Messages exposing (Msg(..))

completion : Artifact -> Html AppMsg
completion artifact =
  div [ class "clearfix py1" ]
    [ div [ class "col col-6" ] 
      [ span [class "bold" ] [ text "Completed: " ]
      , completedPerc artifact
      ]
    , div [ class "col col-6" ] 
      [ span [class "bold" ] [ text "Tested: " ]
      , testedPerc artifact
      ]
    ]

completedPerc : Artifact -> Html msg
completedPerc artifact =
  text <| (String.left 3 (toString (artifact.completed * 100))) ++ "%"

testedPerc : Artifact -> Html msg
testedPerc artifact =
  text <| (String.left 3 (toString (artifact.tested * 100))) ++ "%"

defined : Model -> Artifact -> Html AppMsg
defined model artifact =
  div [] 
  [ span [class "bold" ] [ text "Defined at: " ]
  , text artifact.path
  ]

implemented : Model -> Artifact -> Html m
implemented model artifact =
  div [] 
    (case artifact.loc of
      Just loc ->
        [ span [class "bold" ] [ text "Implemented at: " ]
        , implementedBasic model artifact
        ]
      Nothing ->
        []
    )

implementedBasic : Model -> Artifact -> Html m
implementedBasic model artifact = 
  (case artifact.loc of 
    Just loc ->
      text (loc.path ++ " (" ++ (toString loc.row) 
            ++ "," ++ (toString loc.col) ++ ")"
           )
    Nothing ->
      span [class "italic" ] [ text "not directly implemented" ])

parts : Model -> Artifact -> Html AppMsg
parts model artifact =
  let
    rawParts = List.map (\p -> p.raw) artifact.parts
  in
    ul
      [ id ("parts_" ++ artifact.name.value) ] 
      (List.map (\p -> li [ class "underline" ] [ seeArtifactName model p ]) rawParts)


-- TODO: allow editing when not readonly
partof : Model -> Artifact -> Html AppMsg
partof model artifact =
  let
    rawPartof = List.map (\p -> p.raw) artifact.partof
  in
    ul 
      [ id ("partof_" ++ artifact.name.value) ] 
      (List.map (\p -> li [ class "underline" ] [ seeArtifactName model p ]) rawPartof)

-- TODO: don't wrap text
textPiece : Model -> Artifact -> Html AppMsg
textPiece model artifact =
  let
    ro = model.settings.readonly
    text_part = String.left 200 artifact.text.value
    t = if (String.length artifact.text.value) > 200 then
      text_part ++ " ..."
    else
      text_part
  in
    text text_part

seeArtifact : Model -> Artifact -> Html AppMsg
seeArtifact model artifact =
  let
    ro = model.settings.readonly
  in
    button 
      [ class "btn bold"
      , onClick (ArtifactsMsg <| ShowArtifact <| artifact.name.value)
      , href (artifactNameUrl artifact.name.value)
      , id artifact.name.value
      ]
      [ text (artifact.name.raw ++ "  ")
      , i [ class <| if ro then "bold fa fa-eye mr1" else "bold fa fa-pencil mr1" 
        , href (artifactNameUrl artifact.name.value) 
        ] []
      
      ]

-- TODO: do color and other special stuff for non-existent names
seeArtifactName : Model -> String -> Html AppMsg
seeArtifactName model name =
  let
    indexName = indexNameUnchecked name
    hasName = \a -> a.name.value == indexName
    exists = case List.head <| List.filter hasName model.artifacts of
      Just _ -> True
      Nothing -> False

    url = (artifactNameUrl name)
  in 
    if exists then
      span 
        [ href url
        , onClick ( RouteChange <| ArtifactNameRoute <| indexNameUnchecked name ) 
        ] [ text name ]
    else
      span [ title "Name not found" ] [ text name ]