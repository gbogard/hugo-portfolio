{
  pkgs = import
    (builtins.fetchTarball {
      name = "nixos-20.09";
      url = "https://github.com/NixOS/nixpkgs/archive/d0bb138fbc33b23dd19155fa218f61eed3cb685f.tar.gz";
      sha256 = "0dym3kg1wwl2npp3l3z7q8mk269kib0yphky2zb16ph42gbyly7l";
    })
    { };
}
