{ lib
, pkgs
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (inputs) NixVirt;
  cfg = config.${namespace}.virtualisation.kvm;
in
{
  options.${namespace}.virtualisation.kvm = {
    vmDomains = mkOption {
      type = types.listOf types.str;
      default = [ "win11-GPU" ];
      description = "List of VM domains to define";
    };
  };

  config = mkIf (cfg.enable && builtins.hasAttr "NixVirt" inputs) {
    virtualisation.libvirt = {
      enable = true;
      connections."qemu:///system" = {
        domains = map (name: {
          definition = pkgs.callPackage ./vm-definitions/${name}.nix {
            inherit (cfg.lookingGlass) kvmfrSize;
          };
        }) cfg.vmDomains;
        pools = [
          {
            definition = NixVirt.lib.pool.writeXML {
              name = "default";
              uuid = "ec93320c-83fc-4b8d-a67d-2eef519cc3fd";
              type = "dir";
              target.path = "/var/lib/libvirt/images";
            };
          }
          {
            definition = NixVirt.lib.pool.writeXML {
              name = "isos";
              uuid = "7f532314-d910-4237-99ed-ca3441e006a1";
              type = "dir";
              target.path = "/var/lib/libvirt/isos";
            };
          }
          {
            definition = NixVirt.lib.pool.writeXML {
              name = "nvram";
              uuid = "adda15d7-edf3-4b16-a968-19317c30805a";
              type = "dir";
              target.path = "/var/lib/libvirt/qemu/nvram";
            };
          }
        ];
      };
    };
  };
}
