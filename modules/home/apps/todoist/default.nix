{ lib
, pkgs
, config
, namespace
, ...
}:
let
	inherit (lib) mkIf;
	inherit (lib.${namespace}) mkBoolOpt;
	cfg = config.${namespace}.apps.todoist;
in
{
	options.${namespace}.apps.todoist = {
		enable = mkBoolOpt false "Enable todoist task manager app";
	};

	config = mkIf cfg.enable {
		home.packages = [ pkgs.todoist-electron ];
	};
}
