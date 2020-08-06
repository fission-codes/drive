let

  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};

in

  pkgs.mkShell {
    buildInputs = [

      # Dev Tools
      pkgs.curl
      pkgs.devd
      pkgs.just
      pkgs.watchexec

      # Language Specific
      pkgs.elmPackages.elm
      pkgs.nodejs-14_x
      pkgs.nodePackages.pnpm

    ];
  }
