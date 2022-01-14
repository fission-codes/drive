module Drive.Item exposing (..)

import FeatherIcons
import FileSystem exposing (Item(..))
import Json.Encode as Json
import List.Extra as List
import String.Ext as String
import Time
import Url
import Webnative.Path as Path exposing (Encapsulated, Path)



-- 🧩


type Kind
    = Directory
    | SymLink
      --
    | Audio
    | Code
    | Image
    | Text
    | Video
    | RichText
      --
    | Other


type alias Item =
    { id : String

    --
    , kind : Kind
    , loading : Bool
    , name : String
    , nameProperties : NameProperties
    , path : Path Encapsulated
    , posixTime : Maybe Time.Posix
    , readOnly : Bool
    , size : Int
    }


type alias NameProperties =
    { base : String
    , extension : String
    }


type alias PortablePath =
    { path : Json.Value }



-- 🏔


audioFileExtensions =
    [ "flac", "m4a", "mp3", "ogg", "wav" ]


codeFileExtensions =
    [ "css", "dhall", "elm", "hs", "html", "js", "ts", "xml" ]


imageFileExtensions =
    [ "bmp", "gif", "jpg", "jpeg", "png", "svg", "webp" ]


textFileExtensions =
    [ "json", "txt", "toml", "yaml", "md" ]


richtextFileExtensions =
    [ "doc", "pdf" ]


videoFileExtensions =
    [ "avi", "m4v", "mkv", "mov", "mp4", "mpeg", "webm" ]



-- 🛠


canRenderKind : Kind -> Bool
canRenderKind kind =
    case kind of
        Directory ->
            False

        SymLink ->
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

        RichText ->
            False

        --
        Other ->
            False


cleanName : String -> String
cleanName name =
    name
        |> String.replace "../" ""
        |> String.replace "./" ""
        |> String.replace "/" "-"


fromFileSystem : FileSystem.Item -> Item
fromFileSystem item =
    let
        name =
            FileSystem.name item

        typ =
            case item of
                HardLink h ->
                    Just h.typ

                SoftLink _ ->
                    Nothing

        nameProps =
            case typ of
                Just "dir" ->
                    { base = name
                    , extension = ""
                    }

                _ ->
                    nameProperties name

        lowercaseExtension =
            String.toLower nameProps.extension

        kind =
            case typ of
                Just "dir" ->
                    Directory

                Just "file" ->
                    if List.member lowercaseExtension audioFileExtensions then
                        Audio

                    else if List.member lowercaseExtension codeFileExtensions then
                        Code

                    else if List.member lowercaseExtension imageFileExtensions then
                        Image

                    else if List.member lowercaseExtension textFileExtensions then
                        Text

                    else if List.member lowercaseExtension richtextFileExtensions then
                        RichText

                    else if List.member lowercaseExtension videoFileExtensions then
                        Video

                    else
                        Other

                _ ->
                    case item of
                        SoftLink _ ->
                            SymLink

                        _ ->
                            Other
    in
    case item of
        HardLink { cid, path, posixTime, readOnly, size } ->
            { id = cid

            --
            , kind = kind
            , loading = False
            , name = name
            , nameProperties = nameProps
            , path = Path.fromPosix path
            , posixTime = posixTime
            , readOnly = readOnly
            , size = size
            }

        SoftLink { ipns, path, readOnly } ->
            { id = ipns ++ "/" ++ path

            --
            , kind = kind
            , loading = False
            , name = name
            , nameProperties = nameProps
            , path = Path.fromPosix path
            , posixTime = Nothing
            , readOnly = readOnly
            , size = 0
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


portablePath : Item -> PortablePath
portablePath item =
    { path = Path.encode item.path }


publicUrl : String -> Item -> String
publicUrl base item =
    if String.endsWith item.name base then
        base

    else
        String.chopEnd "/" base ++ "/" ++ Url.percentEncode item.name


sortingFunction : { isGroundFloor : Bool } -> Item -> Item -> Order
sortingFunction { isGroundFloor } a b =
    -- Put directories on top,
    -- and then sort alphabetically by name
    let
        ( aIsPublic, bIsPublic ) =
            ( a.name == "public"
            , b.name == "public"
            )

        compareName c d =
            compare (String.toLower c.name) (String.toLower d.name)
    in
    case ( a.kind, b.kind, isGroundFloor && (aIsPublic || bIsPublic) ) of
        ( _, _, True ) ->
            if aIsPublic then
                LT

            else
                GT

        ( Directory, Directory, _ ) ->
            compareName a b

        ( Directory, _, _ ) ->
            LT

        ( _, Directory, _ ) ->
            GT

        ( _, _, _ ) ->
            compareName a b



-- 🖼


canBeOpenedWithEditor : Item -> Bool
canBeOpenedWithEditor item =
    item.kind == Code || item.kind == Text


generateExtensionForKind : Kind -> String
generateExtensionForKind kind =
    case kind of
        Code ->
            ".html"

        Other ->
            ""

        RichText ->
            ".md"

        Text ->
            ".txt"

        _ ->
            ""


generateExtensionForKindDescription : Kind -> String
generateExtensionForKindDescription kind =
    case kind of
        RichText ->
            "Markdown"

        Code ->
            "HTML"

        Other ->
            "File without extension"

        _ ->
            kindName kind


generateExtensionForKindShortDescription : Kind -> String
generateExtensionForKindShortDescription kind =
    case generateExtensionForKindDescription kind of
        "File without extension" ->
            "File w/o ext"

        desc ->
            desc


kindIcon : Kind -> FeatherIcons.Icon
kindIcon kind =
    case kind of
        Directory ->
            FeatherIcons.folder

        SymLink ->
            FeatherIcons.link

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

        RichText ->
            FeatherIcons.fileText

        --
        Other ->
            FeatherIcons.file


kindName : Kind -> String
kindName kind =
    case kind of
        Directory ->
            "Directory"

        SymLink ->
            "Symlink"

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

        RichText ->
            "Rich Text"

        --
        Other ->
            "File"


nameIcon : Item -> Maybe FeatherIcons.Icon
nameIcon item =
    nameIconForBasename item.nameProperties.base


nameIconForBasename : String -> Maybe FeatherIcons.Icon
nameIconForBasename basename =
    case basename of
        "Apps" ->
            Just FeatherIcons.package

        "Applications" ->
            Just FeatherIcons.package

        --
        "Audio" ->
            Just FeatherIcons.music

        --
        "Docs" ->
            Just FeatherIcons.fileText

        "Documents" ->
            Just FeatherIcons.fileText

        --
        "Movies" ->
            Just FeatherIcons.video

        "Video" ->
            Just FeatherIcons.video

        "Videos" ->
            Just FeatherIcons.video

        --
        "Photos" ->
            Just FeatherIcons.image

        "Pictures" ->
            Just FeatherIcons.image

        --
        "Shared with me" ->
            Just FeatherIcons.users

        --
        _ ->
            Nothing
