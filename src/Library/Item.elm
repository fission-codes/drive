module Item exposing (..)

import FeatherIcons
import Ipfs
import List.Extra as List



-- 🧩


type Kind
    = Directory
      --
    | Audio
    | Code
    | Image
    | Text
    | Video
      --
    | Other


type alias Item =
    { kind : Kind
    , loading : Bool
    , name : String
    , nameProperties : NameProperties
    , selected : Bool
    , size : Int
    }


type alias NameProperties =
    { base : String
    , extension : String
    }



-- 🏔


audioFileExtensions =
    [ "flac", "m4a", "mp3", "ogg", "wav" ]


codeFileExtensions =
    [ "css", "dhall", "elm", "hs", "html", "js", "ts", "xml" ]


imageFileExtensions =
    [ "bmp", "gif", "ico", "jpg", "jpeg", "png", "webp" ]


textFileExtensions =
    [ "doc", "json", "txt", "toml", "yaml" ]


videoFileExtensions =
    [ "avi", "m4v", "mkv", "mov", "mp4", "mpeg", "webm" ]



-- 🛠


fromIpfs : Ipfs.ListItem -> Item
fromIpfs { name, path, size, typ } =
    let
        nameProps =
            case typ of
                "dir" ->
                    { base = name
                    , extension = ""
                    }

                _ ->
                    nameProperties name

        kind =
            case typ of
                "dir" ->
                    Directory

                "file" ->
                    if List.member nameProps.extension audioFileExtensions then
                        Audio

                    else if List.member nameProps.extension codeFileExtensions then
                        Code

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
    in
    { kind = kind
    , loading = False
    , name = name
    , nameProperties = nameProps
    , selected = False
    , size = size
    }


nameProperties : String -> NameProperties
nameProperties name =
    let
        withoutDots =
            String.split "." name

        ( extension, base ) =
            if List.length withoutDots > 1 then
                withoutDots
                    |> List.unconsLast
                    |> Maybe.map (Tuple.mapSecond <| String.join ".")
                    |> Maybe.withDefault ( "", name )

            else
                ( "", name )
    in
    { base = base
    , extension = extension
    }



-- 🖼


kindIcon : Kind -> FeatherIcons.Icon
kindIcon kind =
    case kind of
        Directory ->
            FeatherIcons.folder

        --
        Audio ->
            FeatherIcons.music

        Code ->
            FeatherIcons.code

        Image ->
            FeatherIcons.image

        Text ->
            FeatherIcons.fileText

        Video ->
            FeatherIcons.video

        --
        Other ->
            FeatherIcons.file
