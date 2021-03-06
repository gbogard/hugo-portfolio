let
  inherit (import ./pkgs.nix) pkgs;
in
{}:
with pkgs; pkgs.stdenv.mkDerivation {
  name = "portfolio-shell";
  buildInputs = [ hugo ];
}
