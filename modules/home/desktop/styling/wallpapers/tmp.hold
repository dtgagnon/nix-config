{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.styling.wallpapers;

  inherit (pkgs.spirenix) wallpapers;
  processWallpapers = prefix: wallSet:
    lib.foldl
      (acc: name:
        let 
          value = wallSet.${name};
          newPrefix = if prefix == "" then name else "${prefix}/${name}";
        in
        # If the value has a fileName attribute, it's a wallpaper derivation
        if value ? fileName
        then acc // { "Pictures/wallpapers/${newPrefix}/${value.fileName}".source = value; }
        # Otherwise, it's a nested set that needs recursive processing
        else acc // (processWallpapers newPrefix value)
      )
      { }
      (builtins.attrNames wallSet);
in
{
  options.${namespace}.desktop.styling.wallpapers = {
    enable = mkBoolOpt false "Whether or not to add wallpapers to ~/Pictures/wallpapers.";
  };

  config = mkIf cfg.enable {
    home.file = processWallpapers "" wallpapers;
  };
}

{
  config = mkIf cfg.enable {
    home.file = lib.foldl
      (
        acc: name:
          let
            wallpaper = wallpapers.${name};
          in
          acc // { "Pictures/wallpapers/${wallpaper.fileName}".source = wallpaper; }
      )
      { }
      (wallpapers.names);
  };
}

{
	lib.foldl (acc: name:
	let
		value = wallSet.${name}
	in
	if value ? fileName
	then acc // { "Pictures/wallpapers/${value.fileName}".source = value; }
	else acc // 

		if wallpapers.${name} 
}
