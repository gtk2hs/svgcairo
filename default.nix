{ pkgs ? import nixpkgs ({
    overlays = import ((builtins.fetchTarball {
      url = "https://github.com/input-output-hk/haskell.nix/archive/8d660d8843088264c2f2c2a98c6824264af2efaa.tar.gz";
      sha256 = "03nvscgpi0fak7ssxwyi7zk97als05dmj644a0pn3g60688m8ya7";
    }) + "/overlays");
  })
, nixpkgs ? builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/61f0936d1cd73760312712615233cd80195a9b47.tar.gz";
    sha256 = "1fkmp99lxd827km8mk3cqqsfmgzpj0rvaz5hgdmgzzyji70fa2f8";
  }
, haskellCompiler ? "ghc865"
}:
let
  cabalPatch = pkgs.fetchpatch {
    url = "https://patch-diff.githubusercontent.com/raw/haskell/cabal/pull/6055.diff";
    sha256 = "145g7s3z9q8d18pxgyngvixgsm6gmwh1rgkzkhacy4krqiq0qyvx";
    stripLen = 1;
  };
  project = pkgs.haskell-nix.cabalProject {
    src = pkgs.haskell-nix.haskellLib.cleanGit { src = ./.; };
    pkg-def-extras = [ pkgs.ghc-boot-packages.${haskellCompiler} ];
    ghc = pkgs.buildPackages.pkgs.haskell.compiler.${haskellCompiler};
    modules = [
      { reinstallableLibGhc = true; }
      ({ config, ...}: {
        packages.Cabal.patches = [ cabalPatch ];
      })
    ];
  };
  shells = {
    ghc = (project.shellFor {
      packages = ps: with ps; [
        svgcairo
        ];
    }).overrideAttrs (oldAttrs: {
      shellHook = (oldAttrs.shellHook or "") + ''
        unset CABAL_CONFIG
      '';
    });
  };
in
  project // {
    inherit shells;
  }

