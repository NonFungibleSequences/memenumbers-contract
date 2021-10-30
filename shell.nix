with (import <nixpkgs> { });
let
  pkgs = import (builtins.fetchGit rec {
    name = "dapptools-${rev}";
    url = https://github.com/dapphub/dapptools;
    rev = "d7a23096d8ae8391e740f6bdc4e8b9b703ca4764"; # master @ 2021-10-20
  }) {};

in
  pkgs.mkShell {
    src = null;
    name = "dapptools-template";
    buildInputs = with pkgs; [
      pkgs.dapp
      pkgs.seth
      pkgs.go-ethereum-unlimited
      pkgs.hevm
      pkgs.ethsign

      nodePackages.yarn
    ];
  }
