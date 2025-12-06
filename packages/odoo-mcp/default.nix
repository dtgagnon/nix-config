{
  lib,
  python3,
  writeText,
}:

let
  py = python3;

  script = writeText "odoo-mcp.py" ''
    import sys
    import json
    import urllib.request
    import urllib.error
    import http.cookiejar

    # Configuration
    HOST = "100.100.2.1"
    PORT = 8069
    PROTOCOL = "http"
    URL = f"{PROTOCOL}://{HOST}:{PORT}/jsonrpc"

    # Session storage
    COOKIE_JAR = http.cookiejar.CookieJar()
    OPENER = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(COOKIE_JAR))

    def json_rpc(method, params=None):
        """
        Helper to send JSON-RPC requests to Odoo.
        """
        if params is None:
            params = {}
        
        data = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        }
        
        req = urllib.request.Request(
            URL, 
            data=json.dumps(data).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        
        try:
            with OPENER.open(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                if 'error' in result:
                    raise Exception(result['error'])
                return result.get('result')
        except urllib.error.URLError as e:
            raise Exception(f"Connection failed: {e}")

    def login(db, user, password):
        """
        Authenticate with Odoo and establish a session.
        """
        # Common controller for authentication
        return json_rpc("call", {
            "service": "common",
            "method": "login",
            "args": [db, user, password]
        })

    def execute_kw(model, method, args=None, kwargs=None):
        """
        Execute a method on a model using the 'call' controller (requires session).
        """
        if args is None: args = []
        if kwargs is None: kwargs = {}
        
        return json_rpc("call", {
            "model": model,
            "method": method,
            "args": args,
            "kwargs": kwargs
        })

    def search_read(model, domain, fields=None, limit=None):
        return execute_kw(model, "search_read", [domain], {"fields": fields, "limit": limit})

    def write(model, ids, vals):
        return execute_kw(model, "write", [ids, vals])

    def inspect_model(model):
        return execute_kw(model, "fields_get", [], {"attributes": ["string", "help", "type"]})

    def main():
        # Basic MCP implementation
        while True:
            try:
                line = sys.stdin.readline()
                if not line:
                    break
                
                request = json.loads(line)
                method = request.get("method")
                params = request.get("params", {})
                id = request.get("id")

                result = None
                error = None

                try:
                    if method == "tools/list":
                        result = {
                            "tools": [
                                {
                                    "name": "login",
                                    "description": "Login to Odoo database to establish session",
                                    "inputSchema": {
                                        "type": "object",
                                        "properties": {
                                            "db": {"type": "string"},
                                            "user": {"type": "string"},
                                            "password": {"type": "string"}
                                        },
                                        "required": ["db", "user", "password"]
                                    }
                                },
                                {
                                    "name": "search_read",
                                    "description": "Search and read records from a model",
                                    "inputSchema": {
                                        "type": "object",
                                        "properties": {
                                            "model": {"type": "string"},
                                            "domain": {"type": "array"},
                                            "fields": {"type": "array", "items": {"type": "string"}},
                                            "limit": {"type": "integer"}
                                        },
                                        "required": ["model", "domain"]
                                    }
                                },
                                {
                                    "name": "write",
                                    "description": "Update records",
                                    "inputSchema": {
                                        "type": "object",
                                        "properties": {
                                            "model": {"type": "string"},
                                            "ids": {"type": "array", "items": {"type": "integer"}},
                                            "vals": {"type": "object"}
                                        },
                                        "required": ["model", "ids", "vals"]
                                    }
                                },
                                {
                                    "name": "execute",
                                    "description": "Execute a method on a model",
                                    "inputSchema": {
                                        "type": "object",
                                        "properties": {
                                            "model": {"type": "string"},
                                            "method": {"type": "string"},
                                            "args": {"type": "array"},
                                            "kwargs": {"type": "object"}
                                        },
                                        "required": ["model", "method"]
                                    }
                                },
                                {
                                    "name": "inspect_model",
                                    "description": "Get field definitions for a model",
                                    "inputSchema": {
                                        "type": "object",
                                        "properties": {
                                            "model": {"type": "string"}
                                        },
                                        "required": ["model"]
                                    }
                                }
                            ]
                        }
                    elif method == "tools/call":
                        tool_name = params.get("name")
                        tool_args = params.get("arguments", {})
                        
                        if tool_name == "login":
                            uid = login(tool_args.get("db"), tool_args.get("user"), tool_args.get("password"))
                            result = {"content": [{"type": "text", "text": f"Login successful. UID: {uid}"}]}
                        elif tool_name == "search_read":
                            data = search_read(tool_args.get("model"), tool_args.get("domain"), tool_args.get("fields"), tool_args.get("limit"))
                            result = {"content": [{"type": "text", "text": json.dumps(data, default=str)}]}
                        elif tool_name == "write":
                            data = write(tool_args.get("model"), tool_args.get("ids"), tool_args.get("vals"))
                            result = {"content": [{"type": "text", "text": json.dumps(data, default=str)}]}
                        elif tool_name == "execute":
                            data = execute_kw(tool_args.get("model"), tool_args.get("method"), tool_args.get("args", []), tool_args.get("kwargs", {}))
                            result = {"content": [{"type": "text", "text": json.dumps(data, default=str)}]}
                        elif tool_name == "inspect_model":
                            data = inspect_model(tool_args.get("model"))
                            result = {"content": [{"type": "text", "text": json.dumps(data, default=str)}]}
                        else:
                            error = {"code": -32601, "message": "Method not found"}
                    else:
                        pass

                except Exception as e:
                    error = {"code": -32603, "message": str(e)}

                if id is not None:
                    response = {"jsonrpc": "2.0", "id": id}
                    if error:
                        response["error"] = error
                    else:
                        response["result"] = result
                    
                    sys.stdout.write(json.dumps(response) + "\n")
                    sys.stdout.flush()

            except json.JSONDecodeError:
                continue
            except Exception as e:
                sys.stderr.write(f"Error: {e}\n")
                sys.stderr.flush()

    if __name__ == "__main__":
        main()
  '';
in
python3.pkgs.buildPythonApplication {
  pname = "odoo-mcp";
  version = "0.1.0";
  format = "other";

  propagatedBuildInputs = [ py ];

  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ${script} $out/bin/odoo-mcp
    chmod +x $out/bin/odoo-mcp
    # Wrap with python path
    sed -i '1i#!${py}/bin/python' $out/bin/odoo-mcp
  '';

  meta = with lib; {
    description = "MCP server for Odoo database interaction via JSON-RPC";
    license = licenses.mit;
    mainProgram = "odoo-mcp";
  };
}
