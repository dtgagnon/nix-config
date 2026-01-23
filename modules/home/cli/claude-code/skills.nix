{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mapAttrs' nameValuePair filterAttrs hasSuffix removeSuffix;
  cfg = config.${namespace}.cli.claude-code;

  skillsDir = ./skills;

  # Get all .md files from skills directory
  skillFiles = filterAttrs
    (name: type: type == "regular" && hasSuffix ".md" name)
    (builtins.readDir skillsDir);

  # Generate home.file entries: { ".claude/skills/<name>/SKILL.md" = { text = <content>; }; }
  skillEntries = mapAttrs'
    (filename: _:
      let skillName = removeSuffix ".md" filename;
      in nameValuePair
        ".claude/skills/${skillName}/SKILL.md"
        { text = builtins.readFile (skillsDir + "/${filename}"); }
    )
    skillFiles;
in
{
  config = mkIf cfg.enable {
    home.file = skillEntries;
  };
}
