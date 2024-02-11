{lib, ...}: rec {
  # import files in a directory, and stick them into an attrset of the form:
  # { name = <filename without .nix>; value = <relative path>; }
  readDirAttrs = dir: lib.attrsets.mapAttrs' (name: type: {name = lib.strings.removeSuffix ".nix" name; value = (dir + "/${name}");}) (builtins.readDir dir);

  # for use as an argument to pkgs.lua*.withPackages
  luaWithRocksFromDir = { lua, dir, pkgs, luaPackages ? [] }:
    lua.withPackages (ps: let
      rocks = (readDirAttrs dir);
      ps2 = ps // (builtins.mapAttrs (name: rock: (pkgs.callPackage rock ps2)) rocks);
      rockPackages = (builtins.intersectAttrs rocks ps2);
    in luaPackages ++ builtins.attrValues rockPackages);

}
