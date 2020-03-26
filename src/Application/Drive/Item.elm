module Drive.Item exposing (..)

import FeatherIcons
import Ipfs
import List.Extra as List
import Murmur3
import String.Ext as String
import Time



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
    { id : String

    --
    , cid : String
    , kind : Kind
    , loading : Bool
    , name : String
    , nameProperties : NameProperties
    , path : String
    , posixTime : Maybe Time.Posix
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
    [ "bmp", "gif", "jpg", "jpeg", "png", "svg", "webp" ]


textFileExtensions =
    [ "doc", "json", "txt", "toml", "yaml" ]


videoFileExtensions =
    [ "avi", "m4v", "mkv", "mov", "mp4", "mpeg", "webm" ]



-- 🛠


canRenderKind : Kind -> Bool
canRenderKind kind =
    case kind of
        Directory ->
            False

        --
        Audio ->
            True

        Code ->
            False

        Image ->
            True

        Text ->
            False

        Video ->
            True

        --
        Other ->
            False


fromIpfs : Ipfs.ListItem -> Item
fromIpfs { cid, name, path, posixTime, size, typ } =
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
    { id =
        path
            |> Murmur3.hashString 0
            |> String.fromInt

    --
    , cid = cid
    , kind = kind
    , loading = False
    , name = name
    , nameProperties = nameProps
    , path = path
    , posixTime = posixTime
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


publicUrl : String -> Item -> String
publicUrl base item =
    String.chopEnd "/" base ++ "/" ++ item.name


sortingFunction : Item -> Item -> Order
sortingFunction a b =
    -- Put directories on top,
    -- and then sort alphabetically by name
    case ( a.kind, b.kind ) of
        ( Directory, Directory ) ->
            compare (String.toLower a.name) (String.toLower b.name)

        ( Directory, _ ) ->
            LT

        ( _, Directory ) ->
            GT

        ( _, _ ) ->
            compare (String.toLower a.name) (String.toLower b.name)



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


kindName : Kind -> String
kindName kind =
    case kind of
        Directory ->
            "Directory"

        --
        Audio ->
            "Audio"

        Code ->
            "Code"

        Image ->
            "Image"

        Text ->
            "Text"

        Video ->
            "Video"

        --
        Other ->
            "File"
