with (import <nixpkgs> {}).pkgs;
let modifiedHaskellPackages = haskell-ng.packages.ghcjs.override {
      overrides = self: super: {
        engine-io = self.callPackage ../. {};
        todo-mvc = self.callPackage ./. {};
      };
    };
in modifiedHaskellPackages.socket-io.env
