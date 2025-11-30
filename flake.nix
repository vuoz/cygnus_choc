{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: rec {
      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".h" ".json" ".keymap" ".overlay" ".shield" ".yaml" ".yml" "_defconfig" ];

        parts = [ "dongle" "left" "right" ];
        board = "seeeduino_xiao_ble";
        shield = "cygnus_%PART%";
        extraCmakeFlage = ["studio-rpc-usb-uart"];
        enableZmkStudio = true;



        zephyrDepsHash = "";



        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      reset = let
        resetBase = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "reset_firmware";
          src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".h" ".json" ".keymap" ".overlay" ".shield" ".yaml" ".yml" "_defconfig" ];
          board = "seeeduino_xiao_ble";
          shield = "settings_reset";
          zephyrDepsHash = "";

          meta = {
            description = "ZMK settings reset firmware";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };
      in nixpkgs.legacyPackages.${system}.runCommand "reset_firmware" { } ''
        mkdir -p $out
        cp -r ${resetBase}/. $out/
        if [ -f $out/zmk.uf2 ]; then
          mv $out/zmk.uf2 $out/zmk_reset.uf2
        fi
      '';

      combined = nixpkgs.legacyPackages.${system}.symlinkJoin {
        name = "chalk-firmware-complete";
        paths = [ firmware reset ];
      };

      default = combined;

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
