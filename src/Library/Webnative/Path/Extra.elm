module Webnative.Path.Extra exposing (..)

import Drive.Item exposing (Kind(..))
import Json.Decode as Decode exposing (Decoder)
import List.Ext as List
import List.Extra as List
import Webnative.Path as Path exposing (Directory, Encapsulated, File, Kind(..), Path)



-- 🌳


{-| When a path doesn't specify a branch,
which branch is it supposed to be?
-}
defaultBranch : String
defaultBranch =
    "private"



-- 🛠


{-| Add a filename to a directory path, making it a file path.
-}
addFile : String -> Path Directory -> Path File
addFile filename =
    Path.unwrap >> List.add [ filename ] >> Path.file


{-| Add a new last part of the path.
-}
endWith : String -> Path t -> Path t
endWith part =
    Path.map (List.add [ part ])


{-| Make sure a WNFS branch (public, private, etc.) is present in the path.
If not add the default branch.
-}
ensureDefaultBranch : Path t -> Path t
ensureDefaultBranch =
    Path.map
        (\l ->
            case l of
                "public" :: _ ->
                    l

                "private" :: _ ->
                    l

                _ ->
                    defaultBranch :: l
        )


{-| Remove the last part of the path.
-}
init : Path t -> Path t
init =
    Path.map (\l -> Maybe.withDefault l <| List.init <| l)


{-| Length of a path.
-}
length : Path t -> Int
length path =
    List.length (Path.unwrap path)


{-| Head and tail.
-}
uncons : Path t -> Maybe ( String, Path t )
uncons path =
    case Path.unwrap path of
        a :: rest ->
            Just ( a, Path.map (always rest) path )

        [] ->
            Nothing



-- DECODING


decoder : Decoder (Path Encapsulated)
decoder =
    Decode.oneOf
        [ Decode.map Path.encapsulate directoryPathDecoder
        , Decode.map Path.encapsulate filePathDecoder
        ]


directoryPathDecoder : Decoder (Path Directory)
directoryPathDecoder =
    Decode.map
        Path.directory
        (Decode.field "directory" pathPartsDecoder)


filePathDecoder : Decoder (Path File)
filePathDecoder =
    Decode.map
        Path.file
        (Decode.field "file" pathPartsDecoder)


pathPartsDecoder : Decoder (List String)
pathPartsDecoder =
    Decode.list Decode.string
