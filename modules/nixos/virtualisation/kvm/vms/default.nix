{ lib
, config
, namespace
, NixVirt
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.virtualisation;
in
{
  config = mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    virtualisation.libvirt.connections."qemu:///system" = {
      domains = [
        { definition = NixVirt.lib.domains.writeXML (import ./win11-GPU.nix); }
      ];
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
}
