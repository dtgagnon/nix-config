{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  bash,
  zip,
}:
let
  src = fetchFromGitHub {
    owner = "patrup";
    repo = "mcp-libre";
    rev = "edc5123dcd740049c54de9bc9abf8d69b2f1293f";
    hash = "sha256-J0oXBvn5Bejnn6p6cc4He6lfk+aFnuMSgxJBGhcS6EE=";
  };

  pythonEnv = python3.withPackages (ps: [
    ps.mcp
    ps.httpx
    ps.pydantic
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "mcp-libreoffice";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [ zip python3 ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/mcp-libreoffice $out/bin $out/share/libreoffice/extensions

    # Copy the source module
    cp -r src $out/lib/mcp-libreoffice/

    # Patch libremcp.py to use the extension's HTTP API when available
    # This enables live editing of open documents via UNO instead of file conversion

    # First, add extension bridge helper functions after FastMCP import
    cat > /tmp/extension_bridge.py << 'EXTBRIDGE'

# Extension bridge configuration
EXTENSION_HOST = "localhost"
EXTENSION_PORT = 8765
EXTENSION_TIMEOUT = 2.0  # seconds

def _is_extension_available() -> bool:
    """Check if the LibreOffice extension HTTP server is running"""
    try:
        response = httpx.get(
            f"http://{EXTENSION_HOST}:{EXTENSION_PORT}/health",
            timeout=EXTENSION_TIMEOUT
        )
        return response.status_code == 200
    except (httpx.ConnectError, httpx.TimeoutException):
        return False

def _call_extension(tool_name: str, parameters: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Call a tool on the extension HTTP API. Returns result or None on failure."""
    try:
        response = httpx.post(
            f"http://{EXTENSION_HOST}:{EXTENSION_PORT}/tools/{tool_name}",
            json=parameters,
            timeout=30.0
        )
        if response.status_code == 200:
            return response.json()
        return None
    except (httpx.ConnectError, httpx.TimeoutException, Exception):
        return None

def _get_open_documents() -> List[Dict[str, Any]]:
    """Get list of documents currently open in LibreOffice via extension"""
    result = _call_extension("list_open_documents", {})
    if result and result.get("success"):
        return result.get("documents", [])
    return []

def _is_document_open(file_path: str) -> bool:
    """Check if a document is currently open in LibreOffice"""
    path_obj = Path(file_path).resolve()
    for doc in _get_open_documents():
        doc_url = doc.get("url", "")
        if doc_url.startswith("file://"):
            doc_path = Path(doc_url[7:]).resolve()
            if doc_path == path_obj:
                return True
    return False

EXTBRIDGE

    # Insert extension bridge after FastMCP import
    sed -i '/from mcp.server.fastmcp import FastMCP/r /tmp/extension_bridge.py' \
      $out/lib/mcp-libreoffice/src/libremcp.py

    # Add extension check to create_document function
    # This creates the doc in LibreOffice, inserts content, and saves - leaving it open for live editing
    cat > /tmp/create_ext_check.py << 'CREATECHECK'

    # Try extension API first - creates doc in LibreOffice AND leaves it open for live editing
    if _is_extension_available():
        try:
            # Create new document in LibreOffice
            result = _call_extension("create_document_live", {"doc_type": doc_type})
            if result and result.get("success"):
                # Insert content if provided
                if content:
                    _call_extension("insert_text_live", {"text": content})
                # Save to the specified path
                save_result = _call_extension("save_document_live", {"file_path": str(path_obj.absolute())})
                if save_result and save_result.get("success"):
                    return _get_document_info(str(path_obj))
        except Exception:
            pass  # Fall through to CLI method

CREATECHECK

    # Find create_document function and add extension check after mkdir
    sed -i '/def create_document/,/^@mcp.tool()/{
      /path_obj.parent.mkdir(parents=True, exist_ok=True)/r /tmp/create_ext_check.py
    }' $out/lib/mcp-libreoffice/src/libremcp.py

    # Add extension check to insert_text_at_position function
    # Insert after the exists check, before "try:"
    cat > /tmp/insert_ext_check.py << 'INSERTCHECK'

    # Try extension API first for live editing of open documents
    if _is_extension_available() and _is_document_open(path):
        try:
            pos_map = {"start": 0, "end": None, "replace": None}
            ext_position = pos_map.get(position)
            if position == "replace":
                result = _call_extension("insert_text_live", {"text": text, "clear_first": True})
            else:
                result = _call_extension("insert_text_live", {"text": text, "position": ext_position})
            if result and result.get("success"):
                _call_extension("save_document_live", {})
                return _get_document_info(str(path_obj))
        except Exception:
            pass  # Fall through to CLI method

INSERTCHECK

    # Find the insert_text_at_position function and add extension check
    # We insert after 'raise FileNotFoundError' in that function
    sed -i '/def insert_text_at_position/,/^@mcp.tool()/{
      /raise FileNotFoundError.*Document not found.*path/r /tmp/insert_ext_check.py
    }' $out/lib/mcp-libreoffice/src/libremcp.py

    # Add extension check to read_document_text function
    cat > /tmp/read_ext_check.py << 'READCHECK'

    # Try extension API first for reading open documents (gets latest unsaved content)
    if _is_extension_available() and _is_document_open(path):
        try:
            result = _call_extension("get_text_content_live", {})
            if result and result.get("success"):
                text = result.get("content", "")
                return TextContent(
                    content=text,
                    word_count=len(text.split()),
                    char_count=len(text),
                    page_count=result.get("page_count")
                )
        except Exception:
            pass  # Fall through to CLI method

READCHECK

    # Find the read_document_text function and add extension check
    sed -i '/def read_document_text/,/^@mcp.tool()/{
      /raise FileNotFoundError.*Document not found.*path/r /tmp/read_ext_check.py
    }' $out/lib/mcp-libreoffice/src/libremcp.py

    # Add extension check to get_document_info function
    cat > /tmp/info_ext_check.py << 'INFOCHECK'

    # Try extension API first for open documents
    if _is_extension_available() and _is_document_open(path):
        try:
            result = _call_extension("get_document_info_live", {})
            if result and result.get("success"):
                info = result.get("document_info", {})
                return DocumentInfo(
                    path=path,
                    filename=path_obj.name,
                    format=path_obj.suffix.lower().lstrip('.'),
                    size_bytes=path_obj.stat().st_size if path_obj.exists() else 0,
                    modified_time=datetime.fromtimestamp(path_obj.stat().st_mtime) if path_obj.exists() else datetime.now(),
                    exists=path_obj.exists()
                )
        except Exception:
            pass  # Fall through to CLI method

INFOCHECK

    sed -i '/def get_document_info/,/^@mcp.tool()/{
      /return _get_document_info(path)/i\
    # Try extension API first for open documents\
    if _is_extension_available() and _is_document_open(path):\
        try:\
            result = _call_extension("get_document_info_live", {})\
            if result and result.get("success"):\
                return _get_document_info(path)  # Use local info but confirms doc is accessible\
        except Exception:\
            pass
    }' $out/lib/mcp-libreoffice/src/libremcp.py

    # Add extension check to convert_document function for exporting open docs
    cat > /tmp/convert_ext_check.py << 'CONVERTCHECK'

    # Try extension API first if document is open (can export without saving first)
    if _is_extension_available() and _is_document_open(source_path):
        try:
            result = _call_extension("export_document_live", {
                "export_format": target_format,
                "file_path": target_path
            })
            if result and result.get("success"):
                return ConversionResult(
                    source_path=source_path,
                    target_path=target_path,
                    source_format=source_obj.suffix.lower().lstrip('.'),
                    target_format=target_format,
                    success=True,
                    error_message=None
                )
        except Exception:
            pass  # Fall through to CLI method

CONVERTCHECK

    sed -i '/def convert_document/,/^@mcp.tool()/{
      /target_obj.parent.mkdir(parents=True, exist_ok=True)/r /tmp/convert_ext_check.py
    }' $out/lib/mcp-libreoffice/src/libremcp.py

    # Add new format_text MCP tool - write directly to a file and use sed to insert
    cat > /tmp/format_text_tool.py << 'FMTTOOL'

@mcp.tool()
def format_text(path: str, bold: bool = False, italic: bool = False, underline: bool = False,
                font_size: Optional[float] = None, font_name: Optional[str] = None) -> Dict[str, Any]:
    """Apply formatting to selected text in a LibreOffice Writer document.

    This tool requires the document to be open in LibreOffice with text selected.
    It uses the LibreOffice extension for live formatting.

    Args:
        path: Path to the document file (must be open in LibreOffice)
        bold: Apply bold formatting to selection
        italic: Apply italic formatting to selection
        underline: Apply underline formatting to selection
        font_size: Font size in points (e.g., 12, 14, 16)
        font_name: Font family name (e.g., "Arial", "Times New Roman")

    Returns:
        Result dict with success status and any error message
    """
    path_obj = Path(path)
    if not path_obj.exists():
        raise FileNotFoundError(f"Document not found: {path}")

    if not _is_extension_available():
        return {
            "success": False,
            "error": "LibreOffice extension not running. Open the document in LibreOffice first."
        }

    if not _is_document_open(path):
        return {
            "success": False,
            "error": f"Document {path_obj.name} is not open in LibreOffice. Open it first."
        }

    format_params = {}
    if bold:
        format_params["bold"] = True
    if italic:
        format_params["italic"] = True
    if underline:
        format_params["underline"] = True
    if font_size is not None:
        format_params["font_size"] = font_size
    if font_name is not None:
        format_params["font_name"] = font_name

    if not format_params:
        return {
            "success": False,
            "error": "No formatting options specified. Provide at least one: bold, italic, underline, font_size, or font_name"
        }

    result = _call_extension("format_text_live", format_params)

    if result and result.get("success"):
        _call_extension("save_document_live", {})
        return {
            "success": True,
            "message": f"Applied formatting to selected text in {path_obj.name}",
            "formatting_applied": format_params
        }
    else:
        return {
            "success": False,
            "error": result.get("error", "Failed to apply formatting") if result else "Extension call failed"
        }

FMTTOOL

    # Insert format_text tool before "# Main server entry point" comment using simple approach
    # First read the file, insert our tool before the marker, write back
    {
      head -n $(grep -n "# Main server entry point" $out/lib/mcp-libreoffice/src/libremcp.py | cut -d: -f1 | head -1) $out/lib/mcp-libreoffice/src/libremcp.py | head -n -1
      cat /tmp/format_text_tool.py
      echo ""
      tail -n +$(grep -n "# Main server entry point" $out/lib/mcp-libreoffice/src/libremcp.py | cut -d: -f1 | head -1) $out/lib/mcp-libreoffice/src/libremcp.py
    } > /tmp/libremcp_with_format.py
    mv /tmp/libremcp_with_format.py $out/lib/mcp-libreoffice/src/libremcp.py

    # Create wrapper script (expects libreoffice to be on PATH)
    cat > $out/bin/mcp-libreoffice << EOF
#!${bash}/bin/bash
exec ${pythonEnv}/bin/python3 $out/lib/mcp-libreoffice/src/libremcp.py "\$@"
EOF

    chmod +x $out/bin/mcp-libreoffice

    # Build the LibreOffice extension (.oxt)
    pushd plugin
    # Copy LICENSE from repo root (referenced by description.xml)
    cp ../LICENSE .
    # Patch version requirement - upstream uses 7.0 but LibreOffice 25.x needs lower
    sed -i 's/OpenOffice.org-minimal-version value="7.0"/OpenOffice.org-minimal-version value="4.0"/' description.xml
    # Remove types.rdb reference from manifest (file doesn't exist in upstream repo)
    sed -i '/types\.rdb/d' META-INF/manifest.xml
    # Fix ALL relative imports in all pythonpath files
    # Convert "from .module" to "from module"
    for f in pythonpath/*.py; do
      sed -i 's/from \.mcp_server/from mcp_server/g' "$f"
      sed -i 's/from \.ai_interface/from ai_interface/g' "$f"
      sed -i 's/from \.uno_bridge/from uno_bridge/g' "$f"
    done
    # Ensure 'import uno' is at the very top of each file to activate UNO import hooks
    # Also add sys.path setup for module discovery
    for f in pythonpath/registration.py pythonpath/ai_interface.py pythonpath/mcp_server.py; do
      sed -i '1i import uno; import sys, os; _d = os.path.dirname(os.path.abspath(__file__)); _d not in sys.path and sys.path.append(_d)' "$f"
    done
    # Make problematic UNO type imports optional in uno_bridge.py (LibreOffice 25.x compatibility)
    # Create dummy classes instead of None so isinstance() checks work (they'll just never match)
    sed -i 's/from com.sun.star.presentation import XPresentationDocument/class XPresentationDocument: pass  # Dummy: presentation support unavailable/' pythonpath/uno_bridge.py
    sed -i 's/from com.sun.star.document import XDocumentEventListener/class XDocumentEventListener: pass  # Dummy/' pythonpath/uno_bridge.py
    sed -i 's/from com.sun.star.awt import XActionListener/class XActionListener: pass  # Dummy/' pythonpath/uno_bridge.py

    # CRITICAL FIX: isinstance() doesn't work reliably with UNO interfaces
    # Replace isinstance checks with supportsService() which is the proper UNO way
    sed -i 's/isinstance(doc, XTextDocument)/doc.supportsService("com.sun.star.text.TextDocument")/g' pythonpath/uno_bridge.py
    sed -i 's/isinstance(doc, XSpreadsheetDocument)/doc.supportsService("com.sun.star.sheet.SpreadsheetDocument")/g' pythonpath/uno_bridge.py
    sed -i 's/isinstance(doc, XPresentationDocument)/doc.supportsService("com.sun.star.presentation.PresentationDocument")/g' pythonpath/uno_bridge.py
    # Fix critical bug: 'with' context manager closes server before thread can serve
    # Also fix port reuse issue by using a custom server class with SO_REUSEADDR
    cat > /tmp/patch_ai.py << 'PYPATCH'
import sys
with open(sys.argv[1], 'r') as f:
    c = f.read()

# Add a custom TCPServer class that properly sets SO_REUSEADDR (as a string to inject)
custom_server = """
import time

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

    def server_bind(self):
        import socket
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        super().server_bind()

    def server_close(self):
        try:
            self.socket.shutdown(2)  # SHUT_RDWR
        except:
            pass
        try:
            self.socket.close()
        except:
            pass
        super().server_close()
        time.sleep(0.5)  # Give OS time to release the port
"""

# Insert after the socketserver import
c = c.replace('import socketserver', 'import socketserver' + custom_server)

# Replace the with statement with direct assignment using our custom class
c = c.replace(
    'with socketserver.TCPServer(("", self.port), MCPRequestHandler) as server:\n                server.allow_reuse_address = True\n                self.server = server',
    'self.server = ReusableTCPServer(("", self.port), MCPRequestHandler)'
)

# Fix indentation of remaining lines in the block (they had extra 4 spaces)
lines = c.split('\n')
in_block = False
result = []
for line in lines:
    if 'self.server = ReusableTCPServer' in line:
        in_block = True
    if in_block and line.startswith('                ') and 'except' not in line:
        line = line[4:]  # Remove 4 spaces
    if 'except Exception as e:' in line:
        in_block = False
    result.append(line)
with open(sys.argv[1], 'w') as f:
    f.write('\n'.join(result))
PYPATCH
    python3 /tmp/patch_ai.py pythonpath/ai_interface.py

    # Fix JSON parsing with detailed error handling and logging
    cat > /tmp/fix_json_parse.py << 'FIXJSON'
import sys
with open(sys.argv[1], 'r') as f:
    content = f.read()

# Add debug logging and proper UTF-8 error handling
content = content.replace(
    "body = self.rfile.read(content_length).decode('utf-8')",
    "body_bytes = self.rfile.read(content_length)\n            logger.debug(f\"Read {len(body_bytes)} bytes (expected {content_length})\")\n            body = body_bytes.decode('utf-8', errors='strict')"
)

# Improve JSON error message with position info
content = content.replace(
    'self._send_response(400, {"error": "Invalid JSON"})',
    'logger.error(f"JSON parse error at pos {e.pos}: {e.msg}, body preview: {body[:100]}")\n                    self._send_response(400, {"error": f"Invalid JSON at pos {e.pos}: {e.msg}"})'
)

with open(sys.argv[1], 'w') as f:
    f.write(content)
FIXJSON
    python3 /tmp/fix_json_parse.py pythonpath/ai_interface.py

    zip -r $out/share/libreoffice/extensions/libreoffice-mcp-extension.oxt \
      META-INF/ \
      pythonpath/ \
      *.xml \
      *.xcu \
      *.txt \
      LICENSE \
      -x "*.pyc" "*/__pycache__/*"
    popd

    runHook postInstall
  '';

  meta = {
    description = "LibreOffice MCP server for AI assistants - create, read, convert documents";
    homepage = "https://github.com/patrup/mcp-libre";
    license = lib.licenses.mit;
    mainProgram = "mcp-libreoffice";
    platforms = lib.platforms.unix;
  };
}
