# rock-candy
Flake for packaging and using [luarocks](https://luarocks.org/) in Nix without having to [make changes in nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/lua-modules/generated-packages.nix).

Makes use of [nix-luarocks](https://github.com/nix-community/luarocks-nix), a fork of the luarocks cli that can generate nix packages for luarocks.
As far as I can tell, those generated packages are intended to be inserted into nixpkgs, but having to fork nixpkgs again to add a small handful of packages is a pain. I wrote this flake so that I could reference it from other flakes and pull in any luarocks I want without a hassle.

# Usage example
This is how I packaged croissant in this flake.

The generate script assumes you want to write into a folder whose name ends with luarocks.
```
$ mkdir generated-luarocks && cd generated-luarocks 
```

I'm referring to that directory in nix; here's the current state of overlay.nix (look at that in case it's drifted away from this readme)
If you are referencing the flake from another flake, `./lib` is exported as a flake output named `lib`, so you should be able to use `luaWithRocksFromDir` elsewhere with your own set of luarocks. I don't have an example of this yet but I'll mention it here when I do.
```
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
```

```
$ nix run .#gen croissant
wrote to and git added croissant.nix. you may need to add these dependencies if they don't already exist:
[ "argparse" "buildLuarocksPackage" "compat53" "hump" "lpeg" "sirocco" ]
```

my overlay and packages for this flake tell me that I am missing dependencies when I try to build:
```
$ nix build .#croissant
error:
       … while calling the 'derivationStrict' builtin

         at /builtin/derivation.nix:9:12: (source not available)

       … while evaluating derivation 'croissant'
         whose name attribute is located at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/stdenv/generic/make-derivation.nix:352:7

       … while evaluating attribute 'text' of derivation 'croissant'

         at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/build-support/trivial-builders/default.nix:162:16:

          161|       ({
          162|         inherit text executable checkPhase allowSubstitutes preferLocalBuild;
             |                ^
          163|         passAsFile = [ "text" ]

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: evaluation aborted with the following error message: 'lib.customisation.callPackageWith: Function called without required argument "hump" at /nix/store/8nz7yr5k3wijdgakq9aq2askbh04vgmq-generated-luarocks/croissant.nix:1, did you mean "bump", "dump" or "jump"?'
```

Note the last line about a missing required argument, that's the package we're missing.

Still in the generated-luarocks dir:

```
$ nix run .#gen hump
```

```
$ nix build .#croissant
error:
       … while calling the 'derivationStrict' builtin

         at /builtin/derivation.nix:9:12: (source not available)

       … while evaluating derivation 'croissant'
         whose name attribute is located at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/stdenv/generic/make-derivation.nix:352:7

       … while evaluating attribute 'text' of derivation 'croissant'

         at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/build-support/trivial-builders/default.nix:162:16:

          161|       ({
          162|         inherit text executable checkPhase allowSubstitutes preferLocalBuild;
             |                ^
          163|         passAsFile = [ "text" ]

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: evaluation aborted with the following error message: 'lib.customisation.callPackageWith: Function called without required argument "sirocco" at /nix/store/hx4h7b147lr5ilgd2ymhw1zqwbg24j9i-generated-luarocks/croissant.nix:2, did you mean "shocco"?'
```

Now I can see that I'm missing sirocco. I add that, and try to run croissant again
```
$ nix run .#gen sirocco
$ nix run .#croissant
path '/home/vivlim/git/luarocks-nixflake/generated-luarocks' does not contain a 'flake.nix', searching up
warning: Git tree '/home/vivlim/git/luarocks-nixflake' is dirty
error:
       … while calling the 'derivationStrict' builtin

         at /builtin/derivation.nix:9:12: (source not available)

       … while evaluating derivation 'croissant'
         whose name attribute is located at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/stdenv/generic/make-derivation.nix:352:7

       … while evaluating attribute 'text' of derivation 'croissant'

         at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/build-support/trivial-builders/default.nix:162:16:

          161|       ({
          162|         inherit text executable checkPhase allowSubstitutes preferLocalBuild;
             |                ^
          163|         passAsFile = [ "text" ]

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: evaluation aborted with the following error message: 'lib.customisation.callPackageWith: Function called without required argument "wcwidth" at /nix/store/ga2nkqjxnrslyvf7pland7vn6rds5ha7-source/generated-luarocks/sirocco.nix:2'

```
sirocco needs wcwidth, so let's add that too:
```
$ nix run .#gen wcwidth
```

now, i can run croissant!

```
$ nix run .#croissant
🥐  Croissant 0.0.1 (C) 2019 Benoit Giannangeli
Lua 5.2 Copyright (C) 1994-2018 Lua.org, PUC-Rio
→ print("hello")
hello

```

TIP: make sure you don't have any .nix files in the folder that *aren't* packages or you'll get some very cryptic errors, e.g.
```
$ nix run .#croissant
path '/home/vivlim/git/luarocks-nixflake/generated-luarocks' does not contain a 'flake.nix', searching up
warning: Git tree '/home/vivlim/git/luarocks-nixflake' is dirty
error:
       … while calling the 'derivationStrict' builtin

         at /builtin/derivation.nix:9:12: (source not available)

       … while evaluating derivation 'croissant'
         whose name attribute is located at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/stdenv/generic/make-derivation.nix:352:7

       … while evaluating attribute 'text' of derivation 'croissant'

         at /nix/store/y7k6gpjwwspbpwvw3vax3xc3y53qg0rj-source/pkgs/build-support/trivial-builders/default.nix:162:16:

          161|       ({
          162|         inherit text executable checkPhase allowSubstitutes preferLocalBuild;
             |                ^
          163|         passAsFile = [ "text" ]

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: 'functionArgs' requires a function

       at «none»:0: (source not available)
```
