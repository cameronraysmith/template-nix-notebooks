{
  description = "This nix flake produces a development environment running jupyter with multiple kernels.";

  nixConfig.extra-substituters = "https://jupyterwith.cachix.org";
  nixConfig.extra-trusted-public-keys = "jupyterwith.cachix.org-1:/kDy2B6YEhXGJuNguG1qyqIodMyO4w8KwWH4/vAc7CI=";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jupyterWith.url = "github:tweag/jupyterWith";
    stable.url = "github:NixOS/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , stable
    , jupyterWith
    , flake-utils }:
    (flake-utils.lib.eachDefaultSystem
      (system:

        let

          pkgs = import nixpkgs {

            system = system;
            overlays = nixpkgs.lib.attrValues jupyterWith.overlays ++ [ self.overlay ];
            config = {
              allowBroken = true;
              allowUnfree = true;
              allowUnsupportedSystem = true;
            };

          };

          iPython = pkgs.kernels.iPythonWith {

            name = "Python-env";
            packages = p: with p; [ markdown sympy numpy ];
            ignoreCollisions = true;

          };

          jupyterEnvironment = pkgs.jupyterlabWith {

            kernels = [ iPython ];

          };

          buildImage = pkgs.mkDockerImage {

            name = "template-nix-notebooks";
            jupyterlab = jupyterEnvironment;

          };

        in rec {

          apps.jupyterlab = {

            type = "app";
            program = "${jupyterEnvironment}/bin/jupyter-lab";

          };

          defaultApp = apps.jupyterlab;

          devShell = jupyterEnvironment.env;

          packages = {

            jupyterEnvironment = jupyterEnvironment;
            ociImage = buildImage;

          };

          defaultPackage = self.packages.${system}.jupyterEnvironment;

          checks = {

            markdownlint = pkgs.runCommand "mdl"
              {
                buildInputs = with pkgs; [ mdl ];
              }
              ''
                mkdir $out
                mdl ${./README.md}
              '';

            yamllint = pkgs.runCommand "yamllint"
              {
                buildInputs = with pkgs; [ yamllint ];
              }
              ''
                mkdir $out
                yamllint --strict ${./.github/workflows}
              '';
          };
         }
         )
       ) // {
         overlay = final: prev: { };
       };
}