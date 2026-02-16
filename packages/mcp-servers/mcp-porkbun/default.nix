{
  lib,
  stdenvNoCC,
  python3,
  bash,
}:
let
  # Python MCP server for Porkbun domain registrar API
  serverScript = ''
    #!/usr/bin/env python3
    """MCP server for Porkbun domain registrar API."""

    import os
    import json
    import httpx
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Tool, TextContent

    # Configuration from environment
    BASE_URL = "https://api.porkbun.com/api/json/v3"
    API_KEY = os.environ.get("PORKBUN_API_KEY", "")
    SECRET_KEY = os.environ.get("PORKBUN_SECRET_KEY", "")

    def get_auth():
        return {
            "apikey": API_KEY,
            "secretapikey": SECRET_KEY,
        }

    def api_request(endpoint: str, data: dict | None = None) -> dict:
        """Make an API request to Porkbun. All endpoints use POST with auth in body."""
        url = f"{BASE_URL}{endpoint}"
        body = {**get_auth(), **(data or {})}

        with httpx.Client() as client:
            response = client.post(url, json=body)
            return response.json()

    # Initialize MCP server
    server = Server("porkbun")

    @server.list_tools()
    async def list_tools():
        return [
            # Domain management tools
            Tool(
                name="list_domains",
                description="List all domains in the Porkbun account",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "start": {"type": "integer", "description": "Pagination start index (returns 1000 per request)"},
                        "includeLabels": {"type": "string", "enum": ["yes", "no"], "description": "Include domain labels"},
                    },
                    "required": [],
                },
            ),
            Tool(
                name="get_nameservers",
                description="Get authoritative nameservers for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                    },
                    "required": ["domain"],
                },
            ),
            Tool(
                name="update_nameservers",
                description="Update authoritative nameservers for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "ns": {"type": "array", "items": {"type": "string"}, "description": "List of nameserver hostnames"},
                    },
                    "required": ["domain", "ns"],
                },
            ),
            Tool(
                name="update_auto_renew",
                description="Update auto-renew status for one or more domains",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name (optional if using domains array)"},
                        "status": {"type": "string", "enum": ["on", "off"], "description": "Auto-renew status"},
                        "domains": {"type": "array", "items": {"type": "string"}, "description": "List of domains to update (alternative to single domain)"},
                    },
                    "required": ["status"],
                },
            ),
            Tool(
                name="check_domain",
                description="Check if a domain is available for registration (rate-limited)",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name to check (e.g. example.com)"},
                    },
                    "required": ["domain"],
                },
            ),
            # URL forwarding tools
            Tool(
                name="add_url_forward",
                description="Add URL forwarding for a domain or subdomain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "subdomain": {"type": "string", "description": "Subdomain (optional, empty for root domain)"},
                        "location": {"type": "string", "description": "Destination URL"},
                        "type": {"type": "string", "enum": ["temporary", "permanent"], "description": "Redirect type"},
                        "includePath": {"type": "string", "enum": ["yes", "no"], "description": "Include path in redirect"},
                        "wildcard": {"type": "string", "enum": ["yes", "no"], "description": "Enable wildcard forwarding"},
                    },
                    "required": ["domain", "location", "type", "includePath", "wildcard"],
                },
            ),
            Tool(
                name="get_url_forwarding",
                description="Get all URL forwards configured for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                    },
                    "required": ["domain"],
                },
            ),
            Tool(
                name="delete_url_forward",
                description="Delete a URL forward by record ID",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "record_id": {"type": "string", "description": "Record ID of the URL forward to delete"},
                    },
                    "required": ["domain", "record_id"],
                },
            ),
            # DNS record tools
            Tool(
                name="create_dns_record",
                description="Create a DNS record for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "type": {"type": "string", "enum": ["A", "MX", "CNAME", "ALIAS", "TXT", "NS", "AAAA", "SRV", "TLSA", "CAA", "HTTPS", "SVCB", "SSHFP"], "description": "DNS record type"},
                        "content": {"type": "string", "description": "Record content/value"},
                        "name": {"type": "string", "description": "Subdomain (blank for root, * for wildcard)"},
                        "ttl": {"type": "string", "description": "TTL in seconds (default 600)"},
                        "prio": {"type": "string", "description": "Priority (for MX/SRV records)"},
                        "notes": {"type": "string", "description": "Notes for this record"},
                    },
                    "required": ["domain", "type", "content"],
                },
            ),
            Tool(
                name="edit_dns_record",
                description="Edit a DNS record by ID",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "id": {"type": "string", "description": "Record ID to edit"},
                        "type": {"type": "string", "enum": ["A", "MX", "CNAME", "ALIAS", "TXT", "NS", "AAAA", "SRV", "TLSA", "CAA", "HTTPS", "SVCB", "SSHFP"], "description": "DNS record type"},
                        "content": {"type": "string", "description": "Record content/value"},
                        "name": {"type": "string", "description": "Subdomain"},
                        "ttl": {"type": "string", "description": "TTL in seconds"},
                        "prio": {"type": "string", "description": "Priority"},
                        "notes": {"type": "string", "description": "Notes (empty string clears, null leaves unchanged)"},
                    },
                    "required": ["domain", "id", "type", "content"],
                },
            ),
            Tool(
                name="edit_dns_records_by_name_type",
                description="Edit all DNS records matching a subdomain and type",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "record_type": {"type": "string", "description": "DNS record type (A, AAAA, MX, etc.)"},
                        "subdomain": {"type": "string", "description": "Subdomain to match (blank for root)"},
                        "content": {"type": "string", "description": "New record content/value"},
                        "ttl": {"type": "string", "description": "TTL in seconds"},
                        "prio": {"type": "string", "description": "Priority"},
                        "notes": {"type": "string", "description": "Notes"},
                    },
                    "required": ["domain", "record_type", "subdomain", "content"],
                },
            ),
            Tool(
                name="delete_dns_record",
                description="Delete a DNS record by ID",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "id": {"type": "string", "description": "Record ID to delete"},
                    },
                    "required": ["domain", "id"],
                },
            ),
            Tool(
                name="delete_dns_records_by_name_type",
                description="Delete all DNS records matching a subdomain and type",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "record_type": {"type": "string", "description": "DNS record type"},
                        "subdomain": {"type": "string", "description": "Subdomain to match (blank for root)"},
                    },
                    "required": ["domain", "record_type", "subdomain"],
                },
            ),
            Tool(
                name="retrieve_dns_records",
                description="Retrieve all DNS records for a domain, or a specific record by ID",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "id": {"type": "string", "description": "Specific record ID (omit for all records)"},
                    },
                    "required": ["domain"],
                },
            ),
            Tool(
                name="retrieve_dns_records_by_name_type",
                description="Retrieve DNS records by subdomain and type",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "record_type": {"type": "string", "description": "DNS record type"},
                        "subdomain": {"type": "string", "description": "Subdomain (omit for root)"},
                    },
                    "required": ["domain", "record_type"],
                },
            ),
            # SSL tool
            Tool(
                name="retrieve_ssl_bundle",
                description="Retrieve the SSL certificate bundle (cert chain, private key, public key) for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                    },
                    "required": ["domain"],
                },
            ),
            # DNSSEC tools
            Tool(
                name="create_dnssec_record",
                description="Create a DNSSEC DS record at the registry for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "keyTag": {"type": "string", "description": "Key tag"},
                        "alg": {"type": "string", "description": "Algorithm number"},
                        "digestType": {"type": "string", "description": "Digest type"},
                        "digest": {"type": "string", "description": "Digest value"},
                        "maxSigLife": {"type": "string", "description": "Maximum signature life"},
                        "keyDataFlags": {"type": "string", "description": "Key data flags"},
                        "keyDataProtocol": {"type": "string", "description": "Key data protocol"},
                        "keyDataAlgo": {"type": "string", "description": "Key data algorithm"},
                        "keyDataPubKey": {"type": "string", "description": "Key data public key"},
                    },
                    "required": ["domain", "keyTag", "alg", "digestType", "digest"],
                },
            ),
            Tool(
                name="get_dnssec_records",
                description="Get all DNSSEC DS records for a domain from the registry",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                    },
                    "required": ["domain"],
                },
            ),
            Tool(
                name="delete_dnssec_record",
                description="Delete a DNSSEC DS record by key tag",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "keyTag": {"type": "string", "description": "Key tag of the record to delete"},
                    },
                    "required": ["domain", "keyTag"],
                },
            ),
            # Glue record tools
            Tool(
                name="create_glue_record",
                description="Create a glue record (nameserver IP assignment) for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "subdomain": {"type": "string", "description": "Glue host subdomain (e.g. 'ns1')"},
                        "ips": {"type": "array", "items": {"type": "string"}, "description": "List of IP addresses"},
                    },
                    "required": ["domain", "subdomain", "ips"],
                },
            ),
            Tool(
                name="update_glue_record",
                description="Update a glue record (replaces all existing IPs)",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "subdomain": {"type": "string", "description": "Glue host subdomain"},
                        "ips": {"type": "array", "items": {"type": "string"}, "description": "List of IP addresses (replaces existing)"},
                    },
                    "required": ["domain", "subdomain", "ips"],
                },
            ),
            Tool(
                name="delete_glue_record",
                description="Delete a glue record for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                        "subdomain": {"type": "string", "description": "Glue host subdomain to delete"},
                    },
                    "required": ["domain", "subdomain"],
                },
            ),
            Tool(
                name="get_glue_records",
                description="Get all glue records for a domain",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "domain": {"type": "string", "description": "Domain name"},
                    },
                    "required": ["domain"],
                },
            ),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        result = None

        # Domain management
        if name == "list_domains":
            data = {}
            if "start" in arguments:
                data["start"] = arguments["start"]
            if "includeLabels" in arguments:
                data["includeLabels"] = arguments["includeLabels"]
            result = api_request("/domain/listAll", data)
        elif name == "get_nameservers":
            result = api_request(f"/domain/getNs/{arguments['domain']}")
        elif name == "update_nameservers":
            result = api_request(f"/domain/updateNs/{arguments['domain']}", {"ns": arguments["ns"]})
        elif name == "update_auto_renew":
            domain = arguments.get("domain", "")
            endpoint = f"/domain/updateAutoRenew/{domain}" if domain else "/domain/updateAutoRenew"
            data = {"status": arguments["status"]}
            if "domains" in arguments:
                data["domains"] = arguments["domains"]
            result = api_request(endpoint, data)
        elif name == "check_domain":
            result = api_request(f"/domain/checkDomain/{arguments['domain']}")

        # URL forwarding
        elif name == "add_url_forward":
            data = {
                "location": arguments["location"],
                "type": arguments["type"],
                "includePath": arguments["includePath"],
                "wildcard": arguments["wildcard"],
            }
            if "subdomain" in arguments:
                data["subdomain"] = arguments["subdomain"]
            result = api_request(f"/domain/addUrlForward/{arguments['domain']}", data)
        elif name == "get_url_forwarding":
            result = api_request(f"/domain/getUrlForwarding/{arguments['domain']}")
        elif name == "delete_url_forward":
            result = api_request(f"/domain/deleteUrlForward/{arguments['domain']}/{arguments['record_id']}")

        # DNS record management
        elif name == "create_dns_record":
            data = {"type": arguments["type"], "content": arguments["content"]}
            for key in ("name", "ttl", "prio", "notes"):
                if key in arguments:
                    data[key] = arguments[key]
            result = api_request(f"/dns/create/{arguments['domain']}", data)
        elif name == "edit_dns_record":
            data = {"type": arguments["type"], "content": arguments["content"]}
            for key in ("name", "ttl", "prio", "notes"):
                if key in arguments:
                    data[key] = arguments[key]
            result = api_request(f"/dns/edit/{arguments['domain']}/{arguments['id']}", data)
        elif name == "edit_dns_records_by_name_type":
            data = {"content": arguments["content"]}
            for key in ("ttl", "prio", "notes"):
                if key in arguments:
                    data[key] = arguments[key]
            result = api_request(f"/dns/editByNameType/{arguments['domain']}/{arguments['record_type']}/{arguments['subdomain']}", data)
        elif name == "delete_dns_record":
            result = api_request(f"/dns/delete/{arguments['domain']}/{arguments['id']}")
        elif name == "delete_dns_records_by_name_type":
            result = api_request(f"/dns/deleteByNameType/{arguments['domain']}/{arguments['record_type']}/{arguments['subdomain']}")
        elif name == "retrieve_dns_records":
            endpoint = f"/dns/retrieve/{arguments['domain']}"
            if "id" in arguments:
                endpoint += f"/{arguments['id']}"
            result = api_request(endpoint)
        elif name == "retrieve_dns_records_by_name_type":
            endpoint = f"/dns/retrieveByNameType/{arguments['domain']}/{arguments['record_type']}"
            if "subdomain" in arguments:
                endpoint += f"/{arguments['subdomain']}"
            result = api_request(endpoint)

        # SSL
        elif name == "retrieve_ssl_bundle":
            result = api_request(f"/ssl/retrieve/{arguments['domain']}")

        # DNSSEC
        elif name == "create_dnssec_record":
            data = {
                "keyTag": arguments["keyTag"],
                "alg": arguments["alg"],
                "digestType": arguments["digestType"],
                "digest": arguments["digest"],
            }
            for key in ("maxSigLife", "keyDataFlags", "keyDataProtocol", "keyDataAlgo", "keyDataPubKey"):
                if key in arguments:
                    data[key] = arguments[key]
            result = api_request(f"/dns/createDnssecRecord/{arguments['domain']}", data)
        elif name == "get_dnssec_records":
            result = api_request(f"/dns/getDnssecRecords/{arguments['domain']}")
        elif name == "delete_dnssec_record":
            result = api_request(f"/dns/deleteDnssecRecord/{arguments['domain']}/{arguments['keyTag']}")

        # Glue records
        elif name == "create_glue_record":
            result = api_request(
                f"/domain/createGlue/{arguments['domain']}/{arguments['subdomain']}",
                {"ips": arguments["ips"]},
            )
        elif name == "update_glue_record":
            result = api_request(
                f"/domain/updateGlue/{arguments['domain']}/{arguments['subdomain']}",
                {"ips": arguments["ips"]},
            )
        elif name == "delete_glue_record":
            result = api_request(f"/domain/deleteGlue/{arguments['domain']}/{arguments['subdomain']}")
        elif name == "get_glue_records":
            result = api_request(f"/domain/getGlue/{arguments['domain']}")

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
  pname = "mcp-porkbun";
  version = "0.1.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/mcp-porkbun-server.py << 'PYTHON_EOF'
    ${serverScript}
    PYTHON_EOF

    cat > $out/bin/mcp-porkbun << EOF
    #!${bash}/bin/bash
    exec ${pythonEnv}/bin/python3 $out/bin/mcp-porkbun-server.py "\$@"
    EOF

    chmod +x $out/bin/mcp-porkbun
  '';

  meta = {
    description = "MCP server for Porkbun domain registrar API";
    mainProgram = "mcp-porkbun";
    platforms = lib.platforms.unix;
  };
}
