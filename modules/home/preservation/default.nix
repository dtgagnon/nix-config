{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.preservation;
in
{
  options.${namespace}.preservation = {
    enable = mkBoolOpt true "Whether to enable preservation declarations for this home config.";

    directories = mkOpt (types.listOf (types.either types.str types.attrs)) [ ] ''
      Directories to persist for this user. Paths are relative to $HOME.
      Can be strings or attrsets with additional options like mode.

      Example:
      ```nix
      directories = [
        ".config/myapp"
        { directory = ".gnupg"; mode = "0700"; }
      ];
      ```
    '';

    files = mkOpt (types.listOf (types.either types.str types.attrs)) [ ] ''
      Files to persist for this user. Paths are relative to $HOME.
      Can be strings or attrsets with additional options.

      Example:
      ```nix
      files = [
        ".myapp-config"
        { file = ".secret-file"; mode = "0600"; }
      ];
      ```
    '';
  };

  # No config needed - the NixOS preservation module reads these options
  config = mkIf cfg.enable { };
}
