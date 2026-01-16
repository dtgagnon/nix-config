{
  lib,
  stdenvNoCC,
  python3,
  bash,
}:
let
  # Python MCP server for mxroute API
  serverScript = ''
    #!/usr/bin/env python3
    """MCP server for mxroute email hosting API."""

    import os
    import json
    import httpx
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Tool, TextContent

    # Configuration from environment
    BASE_URL = "https://api.mxroute.com"
    SERVER = os.environ.get("MXROUTE_SERVER", "")
    USERNAME = os.environ.get("MXROUTE_USERNAME", "")
    API_KEY = os.environ.get("MXROUTE_API_KEY", "")

    def get_headers():
        return {
            "X-Server": SERVER,
            "X-Username": USERNAME,
            "X-API-Key": API_KEY,
            "Content-Type": "application/json",
        }

    def api_request(method: str, endpoint: str, data: dict | None = None) -> dict:
        """Make an API request to mxroute."""
        url = f"{BASE_URL}{endpoint}"
        headers = get_headers()

        with httpx.Client() as client:
            if method == "GET":
                response = client.get(url, headers=headers)
            elif method == "POST":
                response = client.post(url, headers=headers, json=data or {})
            elif method == "PATCH":
                response = client.patch(url, headers=headers, json=data or {})
            elif method == "DELETE":
                response = client.delete(url, headers=headers)
            else:
                return {"success": False, "error": {"message": f"Unknown method: {method}"}}

            return response.json()

    # Initialize MCP server
    server = Server("mxroute")

    @server.list_tools()
    async def list_tools():
        return [
            # Domain tools
            Tool(
                name="list_domains",
                description="List all domains on the mxroute account",
                inputSchema={"type": "object", "properties": {}, "required": []},
            ),
            Tool(
                name="get_domain",
                description="Get details for a specific domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="create_domain",
                description="Create a new domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name to create"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="delete_domain",
                description="Delete a domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name to delete"}},
                    "required": ["domain"],
                },
            ),
            # Email account tools
            Tool(
                name="list_email_accounts",
                description="List all email accounts for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="get_email_account",
                description="Get details for a specific email account",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "username": {"type": "string", "description": "Email username (without @domain)"},
                    },
                    "required": ["domain", "username"],
                },
            ),
            Tool(
                name="create_email_account",
                description="Create a new email account",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "username": {"type": "string", "description": "Email username (without @domain)"},
                        "password": {"type": "string", "description": "Account password"},
                        "quota": {"type": "integer", "description": "Quota in MB (optional)"},
                    },
                    "required": ["domain", "username", "password"],
                },
            ),
            Tool(
                name="update_email_account",
                description="Update an email account (password or quota)",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "username": {"type": "string", "description": "Email username"},
                        "password": {"type": "string", "description": "New password (optional)"},
                        "quota": {"type": "integer", "description": "New quota in MB (optional)"},
                    },
                    "required": ["domain", "username"],
                },
            ),
            Tool(
                name="delete_email_account",
                description="Delete an email account",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "username": {"type": "string", "description": "Email username to delete"},
                    },
                    "required": ["domain", "username"],
                },
            ),
            # Forwarder tools
            Tool(
                name="list_forwarders",
                description="List all email forwarders for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="create_forwarder",
                description="Create an email forwarder",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "alias": {"type": "string", "description": "Alias address (without @domain)"},
                        "destinations": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "List of destination email addresses",
                        },
                    },
                    "required": ["domain", "alias", "destinations"],
                },
            ),
            Tool(
                name="delete_forwarder",
                description="Delete an email forwarder",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "alias": {"type": "string", "description": "Alias to delete"},
                    },
                    "required": ["domain", "alias"],
                },
            ),
            # Spam tools
            Tool(
                name="get_spam_settings",
                description="Get spam filter settings for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="update_spam_settings",
                description="Update spam filter settings",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "high_score": {"type": "integer", "description": "Spam score threshold (1-50)"},
                    },
                    "required": ["domain", "high_score"],
                },
            ),
            Tool(
                name="list_spam_whitelist",
                description="List spam whitelist entries",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="add_spam_whitelist",
                description="Add entry to spam whitelist",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "entry": {"type": "string", "description": "Email or domain to whitelist"},
                    },
                    "required": ["domain", "entry"],
                },
            ),
            Tool(
                name="list_spam_blacklist",
                description="List spam blacklist entries",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="add_spam_blacklist",
                description="Add entry to spam blacklist",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "entry": {"type": "string", "description": "Email or domain to blacklist"},
                    },
                    "required": ["domain", "entry"],
                },
            ),
            # DNS info
            Tool(
                name="get_dns_info",
                description="Get DNS configuration records for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            # Catch-all
            Tool(
                name="get_catch_all",
                description="Get catch-all setting for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {"domain": {"type": "string", "description": "Domain name"}},
                    "required": ["domain"],
                },
            ),
            Tool(
                name="set_catch_all",
                description="Set catch-all behavior for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "type": {"type": "string", "enum": ["fail", "blackhole", "address"], "description": "Catch-all type"},
                        "address": {"type": "string", "description": "Forward address (required if type is 'address')"},
                    },
                    "required": ["domain", "type"],
                },
            ),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        result = None

        # Domain operations
        if name == "list_domains":
            result = api_request("GET", "/domains")
        elif name == "get_domain":
            result = api_request("GET", f"/domains/{arguments['domain']}")
        elif name == "create_domain":
            result = api_request("POST", "/domains", {"domain": arguments["domain"]})
        elif name == "delete_domain":
            result = api_request("DELETE", f"/domains/{arguments['domain']}")

        # Email account operations
        elif name == "list_email_accounts":
            result = api_request("GET", f"/domains/{arguments['domain']}/email-accounts")
        elif name == "get_email_account":
            result = api_request("GET", f"/domains/{arguments['domain']}/email-accounts/{arguments['username']}")
        elif name == "create_email_account":
            data = {
                "username": arguments["username"],
                "password": arguments["password"],
            }
            if "quota" in arguments:
                data["quota"] = arguments["quota"]
            result = api_request("POST", f"/domains/{arguments['domain']}/email-accounts", data)
        elif name == "update_email_account":
            data = {}
            if "password" in arguments:
                data["password"] = arguments["password"]
            if "quota" in arguments:
                data["quota"] = arguments["quota"]
            result = api_request("PATCH", f"/domains/{arguments['domain']}/email-accounts/{arguments['username']}", data)
        elif name == "delete_email_account":
            result = api_request("DELETE", f"/domains/{arguments['domain']}/email-accounts/{arguments['username']}")

        # Forwarder operations
        elif name == "list_forwarders":
            result = api_request("GET", f"/domains/{arguments['domain']}/forwarders")
        elif name == "create_forwarder":
            result = api_request("POST", f"/domains/{arguments['domain']}/forwarders", {
                "alias": arguments["alias"],
                "destinations": arguments["destinations"],
            })
        elif name == "delete_forwarder":
            result = api_request("DELETE", f"/domains/{arguments['domain']}/forwarders/{arguments['alias']}")

        # Spam operations
        elif name == "get_spam_settings":
            result = api_request("GET", f"/domains/{arguments['domain']}/spam/settings")
        elif name == "update_spam_settings":
            result = api_request("PATCH", f"/domains/{arguments['domain']}/spam/settings", {
                "high_score": arguments["high_score"],
            })
        elif name == "list_spam_whitelist":
            result = api_request("GET", f"/domains/{arguments['domain']}/spam/whitelist")
        elif name == "add_spam_whitelist":
            result = api_request("POST", f"/domains/{arguments['domain']}/spam/whitelist", {
                "entry": arguments["entry"],
            })
        elif name == "list_spam_blacklist":
            result = api_request("GET", f"/domains/{arguments['domain']}/spam/blacklist")
        elif name == "add_spam_blacklist":
            result = api_request("POST", f"/domains/{arguments['domain']}/spam/blacklist", {
                "entry": arguments["entry"],
            })

        # DNS info
        elif name == "get_dns_info":
            result = api_request("GET", f"/domains/{arguments['domain']}/dns")

        # Catch-all operations
        elif name == "get_catch_all":
            result = api_request("GET", f"/domains/{arguments['domain']}/catch-all")
        elif name == "set_catch_all":
            data = {"type": arguments["type"]}
            if "address" in arguments:
                data["address"] = arguments["address"]
            result = api_request("PATCH", f"/domains/{arguments['domain']}/catch-all", data)

        else:
            result = {"success": False, "error": {"message": f"Unknown tool: {name}"}}

        return [TextContent(type="text", text=json.dumps(result, indent=2))]

    async def main():
        async with stdio_server() as (read_stream, write_stream):
            await server.run(read_stream, write_stream, server.create_initialization_options())

    if __name__ == "__main__":
        import asyncio
        asyncio.run(main())
  '';

  pythonEnv = python3.withPackages (ps: [
    ps.mcp
    ps.httpx
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "mcp-mxroute";
  version = "0.1.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/mcp-mxroute-server.py << 'PYTHON_EOF'
    ${serverScript}
    PYTHON_EOF

    cat > $out/bin/mcp-mxroute << EOF
    #!${bash}/bin/bash
    exec ${pythonEnv}/bin/python3 $out/bin/mcp-mxroute-server.py "\$@"
    EOF

    chmod +x $out/bin/mcp-mxroute
  '';

  meta = {
    description = "MCP server for mxroute email hosting API";
    mainProgram = "mcp-mxroute";
    platforms = lib.platforms.unix;
  };
}
