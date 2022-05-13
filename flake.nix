{
  description = "This is a nix flake for a development environment running jupyter with multiple kernels.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jupyterWith.url = "github:tweag/jupyterWith";
    stable.url = "github:NixOS/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, stable, jupyterWith, flake-utils }: flake-utils.lib.eachDefaultSystem
    (system:

      let

        pkgs = import nixpkgs {

          system = system;
          overlays = nixpkgs.lib.attrValues jupyterWith.overlays;

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

          ociImage = buildImage;

        };

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
      });
}
