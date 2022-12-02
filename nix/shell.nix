{ pkgs ? import <nixpkgs> {} }: with pkgs; let

  # Dependencies
  # ------------

  deps = {

    tools = [
      curl
      jq
      just
      rsync
      simple-http-server
      # watchexec
    ];

    languages = [
      elmPackages.elm
      elmPackages.elm-format
      elmPackages.elm-live
      nodejs-18_x
    ];

  };

in

mkShell {

  buildInputs = builtins.concatLists [
    deps.tools
    deps.languages
  ];

}