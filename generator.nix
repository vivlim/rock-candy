{pkgs, luarocks-nix}: 
{
  gen = pkgs.writeShellScriptBin "gen" ''
    # shell script that writes a luarock nix to the working directory and adds it to git
    export PATH=$PATH:${pkgs.nix-prefetch-git}/bin

    # Need to patch the resulting file so that it accepts arguments other than those it cares about.
    export SED_PATTERN='s/}:$/, ... }:/'

    if [[ "$PWD" == *luarocks ]]; then
      ${luarocks-nix.packages.${pkgs.system}.luarocks-52}/bin/luarocks nix $1 > $1.nix
      ${pkgs.gnused}/bin/sed -i "$SED_PATTERN" $1.nix
      ${pkgs.nixfmt}/bin/nixfmt $1.nix
      git add $1.nix
      echo "wrote to and git added $1.nix. you may need to add these dependencies if they don't already exist:"
      # Import the resulting file, list its function arguments, and exclude ones that aren't packages.
      nix-instantiate --eval -E "builtins.attrNames (builtins.removeAttrs (builtins.functionArgs (import ./$1.nix)) (import ${./non_package_arguments.nix}))"
    else
      echo "not in a dir with a name ending in luarocks, just writing to stdout." >&2
      ${luarocks-nix.packages."${pkgs.system}".luarocks-52}/bin/luarocks nix $1 | ${pkgs.gnused}/bin/sed "$SED_PATTERN"
    fi
  '';
}
