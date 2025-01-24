{ lib
, ...
}:
{
  snowfallHostUserList = (host:
    let
      homes = lib.snowfall.home.get-target-homes-metadata ../../homes/x86_64-linux;

      filteredHomes =
        lib.filter
          (
            home:
            let parsed = lib.snowfall.home.split-user-and-host home.name;
            in parsed.host == "" || parsed.host == host
          )
          homes;

      usernames =
        map
          (home:
            (lib.snowfall.home.split-user-and-host home.name).user
          )
          filteredHomes;
    in
    lib.lists.unique usernames);

}
# {
#   snowfallUserList = lib.lists.unique (map
#     (home:
#       (lib.snowfall.home.split-user-and-host home.name).user
#     )
#     homes);

## Untested code to generate the same user list as above, but only for the current host (the host that will run `nixos-rebuild`).
#
#   filteredHomes =
#     filter (home:
#       let parsed = lib.snowfall.home.split-user-and-host home.name;
#       in parsed.host == "" || parsed.host == host
#     ) homes;
#
#   usernames =
#     map (home:
#       (lib.snowfall.home.split-user-and-host home.name).user
#     ) filteredHomes;
# in
#   lib.lists.unique usernames

## Trying to establish a bridge between home modules and system config. Currently, we have a way to declare in system -> home-manager config.
##TODO: Establish a way to declare in home -> config in system.
# sysToHomeUser = { self, namespace, ... }:
#   let
#     username = self.nixosConfigurations.config.home-manager.users.${ self.nixosConfigurations.config.spirenix.user.name}.${ namespace}.user.name;
#   in
#   {
#     inherit username;
#   };
# }
