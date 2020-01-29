module Item exposing (..)

import FeatherIcons
import Ipfs
import List.Extra as List



-- 🧩


type Kind
    = Directory
      --
    | Audio
    | Image
    | Text
    | Video
      --
    | Other


type alias Item =
    { kind : Kind
    , name : String
    , nameProperties : NameProperties
    , size : Int
    }


type alias NameProperties =
    { base : String
    , extension : String
    }



-- 🏔


audioFileExtensions =
    [ "flac", "m4a", "mp3", "ogg", "wav" ]


imageFileExtensions =
    [ "bmp", "gif", "jpg", "jpeg", "png", "webp" ]


textFileExtensions =
    [ "css", "dhall", "doc", "html", "js", "json", "text", "toml", "xml", "yaml" ]


videoFileExtensions =
    [ "avi", "m4v", "mkv", "mov", "mp4", "mpeg", "webm" ]



-- 🛠


fromIpfs : Ipfs.ListItem -> Item
fromIpfs { name, path, size, typ } =
    let
        nameProps =
            nameProperties name
    in
    { kind =
        case typ of
            "dir" ->
                Directory

            "file" ->
                if List.member nameProps.extension audioFileExtensions then
                    Audio

                else if List.member nameProps.extension imageFileExtensions then
                    Image

                else if List.member nameProps.extension textFileExtensions then
                    Text

                else if List.member nameProps.extension videoFileExtensions then
                    Video

                else
                    Other

            _ ->
                Other

    --
    , name = name
    , nameProperties = nameProps
    , size = size
    }


nameProperties : String -> NameProperties
nameProperties name =
    name
        |> String.split "."
        |> List.uncons
        |> Maybe.withDefault ( name, [] )
        |> Tuple.mapSecond (String.join " . ")
        |> (\( base, extension ) ->
                { base = base
                , extension = extension
                }
           )



-- 🖼


kindIcon : Kind -> FeatherIcons.Icon
kindIcon kind =
    case kind of
        Directory ->
            FeatherIcons.folder

        --
        Audio ->
            FeatherIcons.music

        Image ->
            FeatherIcons.image

        Text ->
            FeatherIcons.fileText

        Video ->
            FeatherIcons.video

        --
        Other ->
            FeatherIcons.file
