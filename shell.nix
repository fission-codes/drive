{ rosetta ? false }:
  let
    overrides = if rosetta then { system = "x86_64-darwin"; } else {};

    sources = import ./nix/sources.nix;
    pkgs    = import sources.nixpkgs overrides;

    commands = import ./nix/commands.nix;
    tasks = commands {pkgs = pkgs;};

    deps = {
      tools = [
        pkgs.curl
        pkgs.devd
        pkgs.just
        pkgs.watchexec
      ];

      elm = [
        pkgs.elmPackages.elm
        pkgs.elmPackages.elm-format
        pkgs.elmPackages.elm-live
      ];

      node = [
        pkgs.nodejs-14_x
        pkgs.nodePackages.pnpm
      ];

      fun = [
        pkgs.figlet
        pkgs.lolcat
      ];
    };

in

  pkgs.mkShell {
    nativeBuildInputs = builtins.concatLists [
      deps.tools
      deps.elm
      deps.node
      deps.fun
      tasks
    ];

    shellHook = ''
      export LANG=C.UTF8

      echo "🌈✨ Welcome to the glorious... "
      ${pkgs.figlet}/bin/figlet "Fission Drive Env" | lolcat -a -s 50
    '';
  }
