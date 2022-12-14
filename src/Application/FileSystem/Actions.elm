module FileSystem.Actions exposing (..)

import Radix exposing (..)
import Task
import Webnative
import Webnative.AppInfo as Webnative
import Webnative.FileSystem as Wnfs exposing (FileSystem)
import Webnative.Path as Path exposing (Directory, File, Path)
import Webnative.Path.Encapsulated as Path
import Webnative.Path.Extra as Path
import Webnative.Permissions as Webnative
import Webnative.Task as Webnative



-- App Info


appData : Wnfs.Base
appData =
    Wnfs.AppData appPermissions


appPermissions : Webnative.AppInfo
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


createDirectory : FileSystem -> Path Directory -> Webnative.Task ()
createDirectory fs path =
    let
        resolved =
            splitPath path
    in
    Wnfs.mkdir fs resolved.base resolved.path


publish : FileSystem -> Webnative.Task ()
publish =
    Task.map (\_ -> ()) << Wnfs.publish


readUtf8 : FileSystem -> Path File -> Webnative.Task String
readUtf8 fs path =
    let
        resolved =
            splitPath path
    in
    Wnfs.readUtf8 fs resolved.base resolved.path


writeUtf8 : FileSystem -> Path File -> String -> Webnative.Task ()
writeUtf8 fs path content =
    let
        resolved =
            splitPath path
    in
    Wnfs.writeUtf8 fs resolved.base resolved.path content



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
