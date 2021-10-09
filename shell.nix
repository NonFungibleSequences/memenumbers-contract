with (import <nixpkgs> { });
let
  pkgs = import (builtins.fetchGit rec {
    name = "dapptools-${rev}";
    url = https://github.com/dapphub/dapptools;
    rev = "009f850d18b48ef7e994fba3186e0bbafcb02d3b"; # master @ 2021-10-09
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
