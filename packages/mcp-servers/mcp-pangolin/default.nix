{
  lib,
  stdenvNoCC,
  python3,
  bash,
}:
let
  # Python MCP server for Pangolin Integration API
  serverScript = ''
    #!/usr/bin/env python3
    """MCP server for Pangolin Integration API.

    Provides tools for managing organizations, sites, resources, targets,
    clients, users, roles, and more via the Pangolin REST API.
    """

    import os
    import json
    import httpx
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Tool, TextContent

    # Configuration from environment
    BASE_URL = os.environ.get("PANGOLIN_BASE_URL", "").rstrip("/")
    API_KEY = os.environ.get("PANGOLIN_API_KEY", "")

    def api_request(method: str, path: str, data: dict | None = None, params: dict | None = None) -> dict:
        """Make an authenticated API request to Pangolin."""
        url = f"{BASE_URL}/v1{path}"
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        }
        query = {k: v for k, v in (params or {}).items() if v is not None}
        with httpx.Client(timeout=30) as client:
            response = client.request(method, url, headers=headers, json=data if data else None, params=query if query else None)
            try:
                return response.json()
            except Exception:
                return {"status": response.status_code, "text": response.text}

    # ---------------------------------------------------------------------------
    # Endpoint definitions: each is (tool_name, description, method, path_template,
    #   path_params, query_params, body_schema)
    # path_params: list of {name, type, description, required}
    # query_params: list of {name, type, description}
    # body_schema: dict of JSON Schema properties (None if no body)
    # ---------------------------------------------------------------------------

    ENDPOINTS = [
        # --- Health ---
        ("health_check", "Check if the Pangolin API is healthy", "GET", "/", [], [], None),

        # # --- Organizations ---
        # ("list_orgs", "List all organizations", "GET", "/orgs", [],
        #  [{"name": "limit", "type": "string", "description": "Max results (default 1000)"},
        #   {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        # ("create_org", "Create a new organization", "PUT", "/org", [], [],
        #  {"type": "object", "properties": {
        #      "orgId": {"type": "string", "description": "Organization ID"},
        #      "name": {"type": "string", "description": "Organization name"},
        #      "subnet": {"type": "string", "description": "Subnet"},
        #      "utilitySubnet": {"type": "string", "description": "Utility subnet"}},
        #   "required": ["orgId", "name", "subnet", "utilitySubnet"]}),
        # ("get_org", "Get an organization by ID", "GET", "/org/{orgId}",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [], None),
        # ("update_org", "Update an organization", "POST", "/org/{orgId}",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [],
        #  {"type": "object", "properties": {
        #      "name": {"type": "string", "description": "New name"},
        #      "requireTwoFactor": {"type": "boolean", "description": "Require 2FA"},
        #      "maxSessionLengthHours": {"type": "number", "description": "Max session length in hours"},
        #      "passwordExpiryDays": {"type": "number", "description": "Password expiry in days"}}}),
        # ("delete_org", "Delete an organization", "DELETE", "/org/{orgId}",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [], None),

        # # --- Domains ---
        # ("list_domains", "List all domains for an organization", "GET", "/org/{orgId}/domains",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
        #  [{"name": "limit", "type": "string", "description": "Max results"},
        #   {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        # ("get_domain", "Get a domain by domainId", "GET", "/org/{orgId}/domain/{domainId}",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True},
        #   {"name": "domainId", "type": "string", "description": "Domain ID", "required": True}], [], None),
        # ("get_domain_dns", "Get all DNS records for a domain", "GET", "/org/{orgId}/domain/{domainId}/dns-records",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True},
        #   {"name": "domainId", "type": "string", "description": "Domain ID", "required": True}], [], None),
        # ("check_namespace", "Check if a domain namespace/subdomain is available", "GET", "/domain/check-namespace-availability",
        #  [], [{"name": "subdomain", "type": "string", "description": "Subdomain to check"}], None),
        # ("list_namespaces", "List all domain namespaces", "GET", "/domains/namepaces", [],
        #  [{"name": "limit", "type": "string", "description": "Max results"},
        #   {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        # ("update_domain", "Update a domain", "PATCH", "/org/{orgId}/domain/{domainId}",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True},
        #   {"name": "domainId", "type": "string", "description": "Domain ID", "required": True}], [], None),

        # # --- Sites ---
        # ("list_sites", "List all sites in an organization", "GET", "/org/{orgId}/sites",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
        #  [{"name": "limit", "type": "string", "description": "Max results"},
        #   {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        # ("create_site", "Create a new site", "PUT", "/org/{orgId}/site",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [],
        #  {"type": "object", "properties": {
        #      "name": {"type": "string", "description": "Site name"},
        #      "type": {"type": "string", "enum": ["newt", "wireguard", "local"], "description": "Site type"},
        #      "exitNodeId": {"type": "integer", "description": "Exit node ID"},
        #      "pubKey": {"type": "string", "description": "WireGuard public key"},
        #      "subnet": {"type": "string", "description": "Subnet"},
        #      "newtId": {"type": "string", "description": "Newt ID"},
        #      "secret": {"type": "string", "description": "Secret"},
        #      "address": {"type": "string", "description": "Address"}},
        #   "required": ["name", "type"]}),
        # ("get_site", "Get a site by siteId", "GET", "/site/{siteId}",
        #  [{"name": "siteId", "type": "string", "description": "Site ID", "required": True}], [], None),
        # ("get_site_by_nice_id", "Get a site by orgId and niceId", "GET", "/org/{orgId}/site/{niceId}",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True},
        #   {"name": "niceId", "type": "string", "description": "Human-readable site ID", "required": True}], [], None),
        # ("update_site", "Update a site", "POST", "/site/{siteId}",
        #  [{"name": "siteId", "type": "string", "description": "Site ID", "required": True}], [],
        #  {"type": "object", "properties": {
        #      "name": {"type": "string", "description": "New name"},
        #      "niceId": {"type": "string", "description": "New nice ID"},
        #      "dockerSocketEnabled": {"type": "boolean", "description": "Enable Docker socket"},
        #      "remoteSubnets": {"type": "string", "description": "Remote subnets"}}}),
        # ("delete_site", "Delete a site and all associated data", "DELETE", "/site/{siteId}",
        #  [{"name": "siteId", "type": "string", "description": "Site ID", "required": True}], [], None),
        # ("pick_site_defaults", "Get pre-requisite data for creating a site (exit node, subnet, credentials)", "GET", "/org/{orgId}/pick-site-defaults",
        #  [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [], None),

        # --- Resources ---
        ("list_resources", "List resources for an organization", "GET", "/org/{orgId}/resources",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
         [{"name": "limit", "type": "string", "description": "Max results"},
          {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        ("list_resource_names", "List all resource names for an organization", "GET", "/org/{orgId}/resources-names",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [], None),
        ("create_resource", "Create a resource (HTTP or raw TCP/UDP)", "PUT", "/org/{orgId}/resource",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}], [],
         {"type": "object", "properties": {
             "name": {"type": "string", "description": "Resource name"},
             "http": {"type": "boolean", "description": "True for HTTP resource, false for raw"},
             "protocol": {"type": "string", "enum": ["tcp", "udp"], "description": "Protocol"},
             "domainId": {"type": "string", "description": "Domain ID (for HTTP resources)"},
             "subdomain": {"type": "string", "description": "Subdomain (for HTTP resources)"},
             "proxyPort": {"type": "integer", "description": "Proxy port (for raw resources, 1-65535)"},
             "stickySession": {"type": "boolean", "description": "Enable sticky sessions"},
             "postAuthPath": {"type": "string", "description": "Post-auth redirect path"}},
          "required": ["name", "http", "protocol"]}),
        ("get_resource", "Get a resource by resourceId", "GET", "/resource/{resourceId}",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}], [], None),
        ("get_resource_by_nice_id", "Get a resource by orgId and niceId", "GET", "/org/{orgId}/resource/{niceId}",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True},
          {"name": "niceId", "type": "string", "description": "Human-readable resource ID", "required": True}], [], None),
        ("update_resource", "Update a resource", "POST", "/resource/{resourceId}",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}], [],
         {"type": "object", "properties": {
             "name": {"type": "string", "description": "New name"},
             "niceId": {"type": "string", "description": "New nice ID"},
             "subdomain": {"type": "string", "description": "Subdomain"},
             "domainId": {"type": "string", "description": "Domain ID"},
             "ssl": {"type": "boolean", "description": "Enable SSL"},
             "sso": {"type": "boolean", "description": "Enable SSO"},
             "blockAccess": {"type": "boolean", "description": "Block access"},
             "enabled": {"type": "boolean", "description": "Enabled"},
             "stickySession": {"type": "boolean", "description": "Sticky sessions"},
             "tlsServerName": {"type": "string", "description": "TLS server name"},
             "setHostHeader": {"type": "string", "description": "Custom Host header"},
             "emailWhitelistEnabled": {"type": "boolean", "description": "Enable email whitelist"},
             "applyRules": {"type": "boolean", "description": "Apply access rules"},
             "maintenanceModeEnabled": {"type": "boolean", "description": "Enable maintenance mode"},
             "maintenanceModeType": {"type": "string", "enum": ["forced", "automatic"], "description": "Maintenance mode type"},
             "maintenanceTitle": {"type": "string", "description": "Maintenance page title"},
             "maintenanceMessage": {"type": "string", "description": "Maintenance page message"},
             "postAuthPath": {"type": "string", "description": "Post-auth redirect path"},
             "headers": {"type": "array", "description": "Custom headers [{name, value}]"},
             "proxyPort": {"type": "integer", "description": "Proxy port (raw resources)"},
             "proxyProtocol": {"type": "boolean", "description": "Enable proxy protocol (raw)"},
             "skipToIdpId": {"type": "integer", "description": "Skip to specific IdP"}}}),
        ("delete_resource", "Delete a resource", "DELETE", "/resource/{resourceId}",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}], [], None),

        # --- Targets ---
        ("list_targets", "List targets for a resource", "GET", "/resource/{resourceId}/targets",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}],
         [{"name": "limit", "type": "string", "description": "Max results"},
          {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        ("create_target", "Create a target for a resource", "PUT", "/resource/{resourceId}/target",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}], [],
         {"type": "object", "properties": {
             "siteId": {"type": "integer", "description": "Site ID"},
             "ip": {"type": "string", "description": "Target IP address"},
             "port": {"type": "integer", "description": "Target port (1-65535)"},
             "method": {"type": "string", "description": "Connection method"},
             "enabled": {"type": "boolean", "description": "Enabled (default true)"},
             "path": {"type": "string", "description": "Path for path-based routing"},
             "pathMatchType": {"type": "string", "enum": ["exact", "prefix", "regex"], "description": "Path match type"},
             "rewritePath": {"type": "string", "description": "Rewrite path"},
             "rewritePathType": {"type": "string", "enum": ["exact", "prefix", "regex", "stripPrefix"], "description": "Rewrite type"},
             "priority": {"type": "integer", "description": "Priority (1-1000)"},
             "hcEnabled": {"type": "boolean", "description": "Enable health checks"},
             "hcPath": {"type": "string", "description": "Health check path"},
             "hcScheme": {"type": "string", "description": "Health check scheme"},
             "hcInterval": {"type": "integer", "description": "Health check interval (seconds)"},
             "hcTimeout": {"type": "integer", "description": "Health check timeout (seconds)"}},
          "required": ["siteId", "ip", "port"]}),
        ("get_target", "Get a target by targetId", "GET", "/target/{targetId}",
         [{"name": "targetId", "type": "string", "description": "Target ID", "required": True}], [], None),
        ("update_target", "Update a target", "POST", "/target/{targetId}",
         [{"name": "targetId", "type": "string", "description": "Target ID", "required": True}], [],
         {"type": "object", "properties": {
             "siteId": {"type": "integer", "description": "Site ID"},
             "ip": {"type": "string", "description": "Target IP"},
             "port": {"type": "integer", "description": "Target port"},
             "method": {"type": "string", "description": "Connection method"},
             "enabled": {"type": "boolean", "description": "Enabled"},
             "path": {"type": "string", "description": "Path for routing"},
             "pathMatchType": {"type": "string", "enum": ["exact", "prefix", "regex"], "description": "Path match type"},
             "rewritePath": {"type": "string", "description": "Rewrite path"},
             "rewritePathType": {"type": "string", "enum": ["exact", "prefix", "regex", "stripPrefix"], "description": "Rewrite type"},
             "priority": {"type": "integer", "description": "Priority"},
             "hcEnabled": {"type": "boolean", "description": "Enable health checks"},
             "hcPath": {"type": "string", "description": "Health check path"},
             "hcInterval": {"type": "integer", "description": "Health check interval"},
             "hcTimeout": {"type": "integer", "description": "Health check timeout"}},
          "required": ["siteId", "ip"]}),
        ("delete_target", "Delete a target", "DELETE", "/target/{targetId}",
         [{"name": "targetId", "type": "string", "description": "Target ID", "required": True}], [], None),

        # # --- Clients ---
        # ("list_clients", ...),
        # ("create_client", ...),
        # ("get_client", ...),
        # ("get_client_by_nice_id", ...),
        # ("update_client", ...),
        # ("delete_client", ...),
        # ("block_client", ...),
        # ("unblock_client", ...),
        # ("archive_client", ...),
        # ("unarchive_client", ...),
        # ("pick_client_defaults", ...),

        # # --- Users ---
        # ("list_users", ...),
        # ("create_user", ...),
        # ("get_user", ...),
        # ("get_org_user", ...),
        # ("update_org_user", ...),
        # ("remove_user", ...),
        # ("check_user_access", ...),
        # ("invite_user", ...),
        # ("list_invitations", ...),
        # ("delete_invitation", ...),

        # # --- Roles ---
        # ("list_roles", ...),
        # ("create_role", ...),
        # ("get_role", ...),
        # ("update_role", ...),
        # ("delete_role", ...),
        # ("add_role_to_user", ...),

        # # --- Resource roles/users/whitelist ---
        # ("list_resource_roles", ...),
        # ("set_resource_roles", ...),
        # ("add_resource_role", ...),
        # ("remove_resource_role", ...),
        # ("list_resource_users", ...),
        # ("set_resource_users", ...),
        # ("add_resource_user", ...),
        # ("remove_resource_user", ...),
        # ("get_resource_whitelist", ...),
        # ("set_resource_whitelist", ...),
        # ("add_whitelist_email", ...),
        # ("remove_whitelist_email", ...),

        # --- Resource rules ---
        ("list_rules", "List access rules for a resource", "GET", "/resource/{resourceId}/rules",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}],
         [{"name": "limit", "type": "string", "description": "Max results"},
          {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        ("create_rule", "Create an access rule for a resource", "PUT", "/resource/{resourceId}/rule",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True}], [],
         {"type": "object", "properties": {
             "action": {"type": "string", "enum": ["ACCEPT", "DROP", "PASS"], "description": "Rule action"},
             "match": {"type": "string", "enum": ["CIDR", "IP", "PATH", "COUNTRY", "ASN"], "description": "Match type"},
             "value": {"type": "string", "description": "Match value"},
             "priority": {"type": "integer", "description": "Rule priority"},
             "enabled": {"type": "boolean", "description": "Enabled"}},
          "required": ["action", "match", "value", "priority"]}),
        ("update_rule", "Update an access rule", "POST", "/resource/{resourceId}/rule/{ruleId}",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True},
          {"name": "ruleId", "type": "string", "description": "Rule ID", "required": True}], [],
         {"type": "object", "properties": {
             "action": {"type": "string", "enum": ["ACCEPT", "DROP", "PASS"], "description": "Rule action"},
             "match": {"type": "string", "enum": ["CIDR", "IP", "PATH", "COUNTRY", "ASN"], "description": "Match type"},
             "value": {"type": "string", "description": "Match value"},
             "priority": {"type": "integer", "description": "Priority"},
             "enabled": {"type": "boolean", "description": "Enabled"}},
          "required": ["priority"]}),
        ("delete_rule", "Delete an access rule", "DELETE", "/resource/{resourceId}/rule/{ruleId}",
         [{"name": "resourceId", "type": "string", "description": "Resource ID", "required": True},
          {"name": "ruleId", "type": "string", "description": "Rule ID", "required": True}], [], None),

        # # --- Resource auth ---
        # ("set_resource_password", ...),
        # ("set_resource_pincode", ...),
        # ("set_resource_header_auth", ...),

        # # --- Access tokens ---
        # ("list_access_tokens", ...),
        # ("list_resource_access_tokens", ...),
        # ("create_access_token", ...),
        # ("delete_access_token", ...),

        # # --- API keys ---
        # ("list_api_keys", ...),
        # ("create_api_key", ...),
        # ("delete_api_key", ...),
        # ("list_api_key_actions", ...),
        # ("set_api_key_actions", ...),

        # --- Logs ---
        ("query_access_logs", "Query access audit log for an organization", "GET", "/org/{orgId}/logs/access",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
         [{"name": "timeStart", "type": "string", "description": "Start time"},
          {"name": "timeEnd", "type": "string", "description": "End time"},
          {"name": "action", "type": "string", "description": "Filter by action"},
          {"name": "resourceId", "type": "string", "description": "Filter by resource"},
          {"name": "actor", "type": "string", "description": "Filter by actor"},
          {"name": "type", "type": "string", "description": "Filter by type"},
          {"name": "location", "type": "string", "description": "Filter by location"},
          {"name": "limit", "type": "string", "description": "Max results"},
          {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        ("query_action_logs", "Query action audit log for an organization", "GET", "/org/{orgId}/logs/action",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
         [{"name": "timeStart", "type": "string", "description": "Start time"},
          {"name": "timeEnd", "type": "string", "description": "End time"},
          {"name": "action", "type": "string", "description": "Filter by action"},
          {"name": "actor", "type": "string", "description": "Filter by actor"},
          {"name": "limit", "type": "string", "description": "Max results"},
          {"name": "offset", "type": "string", "description": "Pagination offset"}], None),
        ("query_request_logs", "Query request audit log for an organization", "GET", "/org/{orgId}/logs/request",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
         [{"name": "timeStart", "type": "string", "description": "Start time"},
          {"name": "timeEnd", "type": "string", "description": "End time"},
          {"name": "method", "type": "string", "description": "HTTP method"},
          {"name": "resourceId", "type": "string", "description": "Filter by resource"},
          {"name": "actor", "type": "string", "description": "Filter by actor"},
          {"name": "host", "type": "string", "description": "Filter by host"},
          {"name": "path", "type": "string", "description": "Filter by path"}], None),
        ("query_analytics", "Query request analytics for an organization", "GET", "/org/{orgId}/logs/analytics",
         [{"name": "orgId", "type": "string", "description": "Organization ID", "required": True}],
         [{"name": "timeStart", "type": "string", "description": "Start time"},
          {"name": "timeEnd", "type": "string", "description": "End time"},
          {"name": "resourceId", "type": "string", "description": "Filter by resource"}], None),

        # # --- Site resources ---
        # ("list_site_resources", ...),
        # ("create_site_resource", ...),
        # ("get_site_resource", ...),
        # ("update_site_resource", ...),
        # ("delete_site_resource", ...),

        # # --- Blueprints ---
        # ("list_blueprints", ...),
        # ("apply_blueprint", ...),
        # ("get_blueprint", ...),

        # # --- Certificates ---
        # ("get_certificate", ...),
        # ("restart_certificate", ...),

        # # --- Billing ---
        # ("get_billing_usage", ...),

        # # --- Maintenance ---
        # ("get_maintenance_info", ...),

        # # --- 2FA ---
        # ("update_user_2fa", ...),
    ]

    # Build tool name -> endpoint mapping
    ENDPOINT_MAP = {}
    for ep in ENDPOINTS:
        ENDPOINT_MAP[ep[0]] = ep

    def build_input_schema(path_params, query_params, body_schema):
        """Build the MCP tool inputSchema from endpoint params."""
        properties = {}
        required = []

        for p in path_params:
            properties[p["name"]] = {"type": p["type"], "description": p["description"]}
            if p.get("required"):
                required.append(p["name"])

        for q in query_params:
            properties[q["name"]] = {"type": q["type"], "description": q["description"]}

        if body_schema:
            body_props = body_schema.get("properties", {})
            body_required = body_schema.get("required", [])
            for k, v in body_props.items():
                properties[k] = v
            required.extend(body_required)

        return {
            "type": "object",
            "properties": properties,
            "required": required,
        }

    def resolve_path(path_template, arguments):
        """Substitute path parameters into the URL template."""
        path = path_template
        for key in list(arguments.keys()):
            placeholder = "{" + key + "}"
            if placeholder in path:
                path = path.replace(placeholder, str(arguments[key]))
        return path

    # Initialize MCP server
    server = Server("pangolin")

    @server.list_tools()
    async def list_tools():
        tools = []
        for name, desc, method, path_template, path_params, query_params, body_schema in ENDPOINTS:
            schema = build_input_schema(path_params, query_params, body_schema)
            tools.append(Tool(name=name, description=desc, inputSchema=schema))
        return tools

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        if name not in ENDPOINT_MAP:
            return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]

        _, desc, method, path_template, path_params, query_params, body_schema = ENDPOINT_MAP[name]

        # Separate path params from body/query params
        path_param_names = {p["name"] for p in path_params}
        query_param_names = {q["name"] for q in query_params}

        path = resolve_path(path_template, arguments)
        query = {k: v for k, v in arguments.items() if k in query_param_names and v is not None}
        body = {k: v for k, v in arguments.items() if k not in path_param_names and k not in query_param_names}

        result = api_request(method, path, data=body if body else None, params=query if query else None)
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
  pname = "mcp-pangolin";
  version = "0.1.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/mcp-pangolin-server.py << 'PYTHON_EOF'
    ${serverScript}
    PYTHON_EOF

    cat > $out/bin/mcp-pangolin << EOF
    #!${bash}/bin/bash
    exec ${pythonEnv}/bin/python3 $out/bin/mcp-pangolin-server.py "\$@"
    EOF

    chmod +x $out/bin/mcp-pangolin
  '';

  meta = {
    description = "MCP server for Pangolin Integration API";
    mainProgram = "mcp-pangolin";
    platforms = lib.platforms.unix;
  };
}
