module FileSystem.Actions exposing (..)

import Codec exposing (Codec)
import Drive.Sidebar
import Json.Decode
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import Webnative
import Webnative.Path as Path exposing (Directory, Encapsulated, File, Path)
import Webnative.Path.Encapsulated as Path
import Webnative.Path.Extra as Path
import Wnfs



-- App Info


appData : Wnfs.Base
appData =
    Wnfs.AppData appPermissions


appPermissions : Webnative.AppPermissions
appPermissions =
    { creator = "Fission"
    , name = "Drive"
    }


permissions : Webnative.Permissions
permissions =
    { app = Just appPermissions
    , fs =
        Just
            { private = { directories = [ Path.root ], files = [] }
            , public = { directories = [ Path.root ], files = [] }
            }
    }



-- Actions


createDirectory : { path : Path Directory, tag : Tag } -> Cmd Msg
createDirectory { path, tag } =
    let
        resolved =
            splitPath path
    in
    Wnfs.mkdir resolved.base
        { path = resolved.path
        , tag = tagToString tag
        }
        |> Ports.webnativeRequest


publish : { tag : Tag } -> Cmd Msg
publish { tag } =
    Wnfs.publish
        { tag = tagToString tag }
        |> Ports.webnativeRequest


writeUtf8 : { path : Path File, tag : Tag, content : String } -> Cmd Msg
writeUtf8 { path, tag, content } =
    let
        resolved =
            splitPath path
    in
    Wnfs.writeUtf8 resolved.base
        { path = resolved.path
        , tag = tagToString tag
        }
        content
        |> Ports.webnativeRequest


readUtf8 : { path : Path File, tag : Tag } -> Cmd Msg
readUtf8 { path, tag } =
    let
        resolved =
            splitPath path
    in
    Wnfs.readUtf8 resolved.base
        { path = resolved.path
        , tag = tagToString tag
        }
        |> Ports.webnativeRequest



-- Codecs


codecTag : Codec Tag
codecTag =
    Codec.custom
        (\cSidebarTag cCreatedEmptyFile cCreatedDirectory cUpdatedFileSystem value ->
            case value of
                SidebarTag a ->
                    cSidebarTag a

                CreatedEmptyFile a ->
                    cCreatedEmptyFile a

                CreatedDirectory ->
                    cCreatedDirectory

                UpdatedFileSystem ->
                    cUpdatedFileSystem
        )
        |> Codec.variant1 "SidebarTag"
            SidebarTag
            (Codec.custom
                (\cSavedFile cLoadedFile value ->
                    case value of
                        Drive.Sidebar.SavedFile a ->
                            cSavedFile a

                        Drive.Sidebar.LoadedFile a ->
                            cLoadedFile a
                )
                |> Codec.variant1 "SavedFile" Drive.Sidebar.SavedFile (codecPathRecord codecFilePath)
                |> Codec.variant1 "LoadedFile" Drive.Sidebar.LoadedFile (codecPathRecord codecFilePath)
                |> Codec.buildCustom
            )
        |> Codec.variant1 "CreatedEmptyFile" CreatedEmptyFile (codecPathRecord codecPath)
        |> Codec.variant0 "CreatedDirectory" CreatedDirectory
        |> Codec.variant0 "UpdatedFileSystem" UpdatedFileSystem
        |> Codec.buildCustom


codecPath : Codec (Path Encapsulated)
codecPath =
    Codec.build
        Path.encode
        Path.decoder


codecDirectoryPath : Codec (Path Directory)
codecDirectoryPath =
    Codec.andThen
        (\v ->
            Maybe.unwrap
                (Codec.fail "Path was not a directory path")
                Codec.succeed
                (Path.toDirectory v)
        )
        Path.encapsulate
        codecPath


codecFilePath : Codec (Path File)
codecFilePath =
    Codec.andThen
        (\v ->
            Maybe.unwrap
                (Codec.fail "Path was not a file path")
                Codec.succeed
                (Path.toFile v)
        )
        Path.encapsulate
        codecPath


codecPathRecord : Codec a -> Codec { path : a }
codecPathRecord pathCodec =
    (\path -> { path = path })
        |> Codec.object
        |> Codec.field "path" .path pathCodec
        |> Codec.buildObject


decodeResponse : Webnative.Response -> Webnative.DecodedResponse Tag
decodeResponse =
    Webnative.decodeResponse tagFromString


tagToString : Tag -> String
tagToString tag =
    Codec.encodeToString 0 codecTag tag


tagFromString : String -> Result String Tag
tagFromString string =
    string
        |> Codec.decodeString codecTag
        |> Result.mapError Json.Decode.errorToString



-- Utilities


splitPath : Path t -> { base : Wnfs.Base, path : Path t }
splitPath path =
    case Path.unwrap path of
        "public" :: rest ->
            { base = Wnfs.Public, path = Path.map (always rest) path }

        "private" :: rest ->
            { base = Wnfs.Private, path = Path.map (always rest) path }

        _ ->
            { base = Wnfs.Private, path = path }
