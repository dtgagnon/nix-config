{ lib
, ...
}:
let
  homes = lib.snowfall.home.get-target-homes-metadata ../../homes/x86_64-linux;
in
{
  snowfallUserList = lib.lists.unique (map
    (home:
      (lib.snowfall.home.split-user-and-host home.name).user
    )
    homes);

  # sysToHomeUser = { self, namespace, ... }:
  #   let
  #     username = self.nixosConfigurations.config.home-manager.users.${ self.nixosConfigurations.config.spirenix.user.name}.${ namespace}.user.name;
  #   in
  #   {
  #     inherit username;
  #   };
}
