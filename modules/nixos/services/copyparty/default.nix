{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.copyparty;

  addAdminAccess = volumes:
    lib.mapAttrs
      (_name: vol:
        let
          access = vol.access or { };
          aVal = access.A or null;
          aList =
            if aVal == null then
              [ ]
            else if lib.isList aVal then
              aVal
            else
              [ aVal ];
          newA =
            if lib.elem "*" aList || lib.elem "@admin" aList then
              aList
            else
              aList ++ [ "@admin" ];
        in
        vol // { access = access // { A = newA; }; }
      )
      volumes;
in
{
  options.${namespace}.services.copyparty = {
    enable = mkBoolOpt false "Enable the copyparty file sharing server.";
    package = mkOpt types.package pkgs.copyparty "Package providing the copyparty binary.";
    storeRoot = mkOpt types.str "/srv/files" "Path of a primary root directory for volumes";
  };

  config = mkIf cfg.enable {
    services.copyparty = {
      enable = true;
      package = cfg.package;

      # mkHashWrapper = true;
      # user = "copyparty";
      # group = "copyparty";

      openFilesLimit = 4096;
      settings = {
        i = "100.100.1.2";
        no-reload = true;
        hist = "/var/cache/copyparty";
        ban-pw = 0; # Disable password-fail banning until client auth is stable
        rproxy = 1;
        xff-src = "100.100.90.1"; # Trust X-Forwarded-For only from oranix (Pangolin)
      };
      globalExtraConfig = "";

      accounts = {
        dtgagnon.passwordFile = "${config.sops.secrets.dtgagnon-copyparty-pass.path}";
        gachan.passwordFile = "${config.sops.secrets.gachan-copyparty-pass.path}";
      };
      groups = {
        admin = [ "dtgagnon" ];
        family = [ "dtgagnon" "gachan" ];
      };

      volumes = addAdminAccess {
        "/" = {
          path = "${cfg.storeRoot}";
          access = { };
          flags = {
            fk = 4;
            scan = 60;
            e2d = false;
            d2t = true;
            nohash = "\.iso$";
          };
        };
        "/public" = {
          path = "${cfg.storeRoot}/public";
          access = {
            rG = [ "*" ];
            wmd = [ "@family" ];
          };
          flags = {
            fk = 4;
            scan = 60;
            e2d = true;
            d2t = true;
            nohash = "\.iso$";
          };
        };
        "/dtgagnon" = {
          path = "${cfg.storeRoot}/dtgagnon";
          access = {
            A = [ "dtgagnon" ];
          };
          flags = {
            scan = 60;
            d2t = true;
          };
        };
        "/gachan" = {
          path = "${cfg.storeRoot}/gachan";
          access = {
            rwmd = [ "gachan" ];
          };
          flags = {
            scan = 60;
            d2t = true;
          };
        };
      };
    };
    sops.secrets = {
      dtgagnon-copyparty-pass.owner = "copyparty";
      gachan-copyparty-pass.owner = "copyparty";
    };
  };
}
