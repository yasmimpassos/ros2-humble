{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    devshell.url = "github:numtide/devshell";
    zenoh.url = "github:gustavowidman/zenoh-plugin-ros2dds-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      systems,
      devshell,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      imports = [
        devshell.flakeModule
      ];
      perSystem =
        { pkgs, system, ... }:
        let
          inherit (pkgs.lib)
            optionalString
            ;

          isDarwin = pkgs.stdenv.isDarwin;

          colconDefaults = pkgs.writeText "defaults.yaml" ''
            build:
              cmake-args:
                - -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
                - -DPython_FIND_VIRTUALENV=ONLY
                - -DPython3_FIND_VIRTUALENV=ONLY
                - -Wno-dev
                ${optionalString isDarwin "- -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"}
          '';
        in
        {
          devshells.default = {
            env = [
              {
                name = "COLCON_DEFAULTS_FILE";
                value = toString colconDefaults;
              }
              {
                name = "ROS_DOMAIN_ID";
                value = 0;
              }
              {
                name = "ROS_LOCALHOST_ONLY";
                value = 1;
              }
              #{
              #  name = "RMW_IMPLEMENTATION";
              #  value = "rmw_cyclonedds_cpp";
              #}
              {
                name = "LIBGL_ALWAYS_SOFTWARE";
                value = 1;
              }
            ];
            devshell = {
              packages = with pkgs; [
                pixi
                inputs.zenoh.packages.${system}.default
              ];
              startup.activate.text = ''
                if [ -f pixi.toml ]; then
                  ${optionalString isDarwin ''
                    export DYLD_FALLBACK_LIBRARY_PATH="$PWD/.pixi/envs/default/lib:$DYLD_FALLBACK_LIBRARY_PATH"
                  ''}

                  #export CYCLONEDDS_URI=${"file://$(realpath cyclonedds.xml)"}

                  eval "$(pixi shell-hook)";

                  # source install/setup.bash
                fi
              '';
              motd = "";
            };
          };
        };
    };
}
