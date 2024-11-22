{ ... }:
{
  sysToHomeUser = { self, namespace, ... }:
    let
      username = self.nixosConfigurations.config.home-manager.users.${self.nixosConfigurations.config.spirenix.user.name}.${namespace}.user.name;
    in
    {
      inherit username;
    };
}
