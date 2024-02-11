{pkgs, nixpkgsFlake, luarocks-nix}: let 
  myLib = (import ./lib) {
    lib = pkgs.lib;
  };
  myLuaEnv = (myLib.luaWithRocksFromDir { lua = pkgs.lua5_2; dir = ./generated-luarocks; inherit pkgs;});
  in {
  croissant-script = pkgs.writeShellScriptBin "croissant" ''
    ${myLuaEnv.out}/bin/croissant $@
  '';
  }
