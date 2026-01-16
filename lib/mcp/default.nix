{ lib, ... }:

rec {
  ## Create a stdio-based MCP server configuration.
  ##
  ## ```nix
  ## mkStdioServer {
  ##   command = "my-mcp-server";
  ##   args = [ "--port" "8080" ];
  ## }
  ## ```
  ##
  #@ { command: String, args?: [String] } -> AttrSet
  mkStdioServer =
    {
      command,
      args ? [ ],
    }:
    {
      transport = "stdio";
      inherit command args;
    };

  ## Create an HTTP-based MCP server configuration.
  ##
  ## ```nix
  ## mkHttpServer {
  ##   url = "https://api.example.com/mcp";
  ##   headers.Authorization = "Bearer \${API_KEY}";
  ## }
  ## ```
  ##
  #@ { url: String, headers?: AttrSet } -> AttrSet
  mkHttpServer =
    {
      url,
      headers ? { },
    }:
    {
      type = "http";
      inherit url;
    }
    // lib.optionalAttrs (headers != { }) { inherit headers; };

  ## Create an MCP server that runs via `nix run` from a flake.
  ## Common pattern for running MCP servers directly from nixpkgs or flake inputs.
  ##
  ## ```nix
  ## mkNixRunServer {
  ##   flake = "github:utensils/mcp-nixos";
  ## }
  ## ```
  ##
  #@ { flake: String, args?: [String] } -> AttrSet
  mkNixRunServer =
    {
      flake,
      args ? [ ],
    }:
    mkStdioServer {
      command = "nix";
      args = [
        "run"
        flake
        "--"
      ]
      ++ args;
    };

  ## Create an MCP server that runs via npx (for npm packages).
  ##
  ## ```nix
  ## mkNpxServer {
  ##   package = "@modelcontextprotocol/server-filesystem";
  ##   args = [ "/path/to/dir" ];
  ## }
  ## ```
  ##
  #@ { package: String, args?: [String] } -> AttrSet
  mkNpxServer =
    {
      package,
      args ? [ ],
    }:
    mkStdioServer {
      command = "npx";
      args = [
        "-y"
        package
      ]
      ++ args;
    };

  ## Create an MCP server with environment variable substitution in the URL.
  ## Convenience wrapper around mkHttpServer for APIs that need auth tokens.
  ##
  ## ```nix
  ## mkHttpServerWithAuth {
  ##   url = "https://api.example.com/mcp";
  ##   authEnvVar = "API_KEY";
  ##   authType = "Bearer";
  ## }
  ## # Results in: { url = "https://api.example.com/mcp?apiKey=${API_KEY}"; ... }
  ## # or with header auth: { headers.Authorization = "Bearer ${API_KEY}"; ... }
  ## ```
  ##
  #@ { url: String, authEnvVar: String, authType?: String, useHeader?: Bool } -> AttrSet
  mkHttpServerWithAuth =
    {
      url,
      authEnvVar,
      authType ? "Bearer",
      useHeader ? true,
    }:
    if useHeader then
      mkHttpServer {
        inherit url;
        headers.Authorization = "${authType} \${${authEnvVar}}";
      }
    else
      mkHttpServer {
        url = "${url}?apiKey=\${${authEnvVar}}";
      };

  ## Create an MCP server using supergateway to bridge HTTP to stdio.
  ## Useful for connecting to n8n, langchain, or other HTTP-based MCP endpoints.
  ##
  ## ```nix
  ## mkSupergatewayServer {
  ##   httpUrl = "http://localhost:5678/mcp-server/http";
  ##   authHeader = "authorization:Bearer \${N8N_TOKEN}";
  ## }
  ## ```
  ##
  #@ { httpUrl: String, authHeader?: String } -> AttrSet
  mkSupergatewayServer =
    {
      httpUrl,
      authHeader ? null,
    }:
    mkNpxServer {
      package = "supergateway";
      args = [
        "--streamableHttp"
        httpUrl
      ]
      ++ lib.optionals (authHeader != null) [
        "--header"
        authHeader
      ];
    };

  ## Create an MCP server from an executable package.
  ## Useful when you have a package in your flake that provides an MCP server.
  ##
  ## ```nix
  ## mkPackageServer {
  ##   package = pkgs.my-mcp-server;
  ##   args = [ "--config" "/path/to/config" ];
  ## }
  ## ```
  ##
  #@ { package: Package, executable?: String, args?: [String] } -> AttrSet
  mkPackageServer =
    {
      package,
      executable ? null,
      args ? [ ],
    }:
    let
      exe = if executable != null then executable else lib.getExe package;
    in
    mkStdioServer {
      command = exe;
      inherit args;
    };
}
