{
  description = "notan";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          rust-overlay.overlays.default
          (final: prev: {
            rustToolchain = prev.rust-bin.stable."1.86.0".default.override {
              targets = [
                "wasm32-unknown-unknown"
              ];
              extensions = [ "rust-src" ];
            };
          })
        ];

        pkgs = import nixpkgs {
          inherit overlays system;
        };

        common = [
          pkgs.gcc14
          pkgs.shaderc
          pkgs.clang_14
          pkgs.cmake
          pkgs.rustToolchain
          pkgs.openssl
          pkgs.ffmpeg_4
          pkgs.wasm-pack
          pkgs.binaryen
          pkgs.wasm-bindgen-cli
          pkgs.bacon
          pkgs.cargo-watch
          pkgs.pkg-config
          pkgs.clippy
        ];

        dev =
          if builtins.getEnv "CI" != "true" then
            [
              pkgs.fswatch
              pkgs.rust-analyzer
            ]
          else
            [ ];
        all = common ++ dev;

        inherit (pkgs) inotify-tools fontconfig;
        inherit (pkgs.lib) optionals;
        inherit (pkgs.stdenv) isDarwin isLinux;

        linuxDeps = optionals isLinux [
          inotify-tools
          fontconfig
        ];
        darwinDeps = optionals isDarwin [ ];

      in
      {
        devShells = {
          default = pkgs.mkShell {
            LOCALE_ARCHIVE =
              if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";

            packages = all ++ linuxDeps ++ darwinDeps;

            shellHook = ''
              export CARGO_INSTALL_ROOT=$PWD/.nix-cargo
              export CARGO_HOME=$PWD/.nix-cargo
              mkdir -p $CARGO_HOME
              export PATH=$CARGO_HOME/bin:bin:$PATH

              export LIBCLANG_PATH="${pkgs.llvmPackages_14.libclang.lib}/lib"
              export UNWRAPPED_CC_BIN="${pkgs.llvmPackages_14.clang-unwrapped}/bin/clang++"
              export LLVM_AR_BIN="${pkgs.llvm_14}/bin/llvm-ar"
            '';
          };
        };
      }
    );
}
