let
  inherit (import <nixpkgs> {}) fetchFromGitHub;

  stablepkgs = fetchFromGitHub {
    owner  = "NixOS";
    repo   = "nixpkgs";

    rev    = "aaa66d8d887c73f643246ac1a684fcb1521543b8";
    sha256 = "0qvrhc7hv8h4yqa4jh64y6v5j3nza53ivkbq6j72g434c3yp2h50";
  };

  unstablepkgs = fetchFromGitHub {
    owner  = "NixOS";
    repo   = "nixpkgs";

    rev    = "6148f6360310366708dff42055a0ba0afa963101";
    sha256 = "1j91hxfak1kark776klszakvg0a9yv77p7lnrvj7g32v6g20qdsk";
  };

  stable   = import stablepkgs   {};
  unstable = import unstablepkgs {};

in
  stablepkgs.stdenv.mkDerivation {
    name = "fission-drive";

    buildInputs = [
      # General
      stable.curl
      stable.devd
      stable.nodejs-13_x
      stable.watchexec

      # Language Specific
      stable.elmPackages.elm
      stable.nodePackages.pnpm

      # Fun
      stable.lolcat
      stable.figlet

      # Unstable
      unstable.just
    ];

    shellHook = ''
      echo "Welcome to the"
      ${stable.figlet}/bin/figlet "Fission Drive Shell" | lolcat -a -s 50
    '';
}
