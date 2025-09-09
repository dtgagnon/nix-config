{ ... }: _final: prev: {
  # Keep tests enabled but skip network-heavy suites; add import sanity check
  python3Packages = prev.python3Packages.overrideScope (_: p: {
    "opensearch-py" = p."opensearch-py".overridePythonAttrs (old: {
      disabledTestPaths = (old.disabledTestPaths or []) ++ [
        # Async secured server tests that require a live OpenSearch cluster
        "test_opensearchpy/test_async"
        # Be conservative and skip any server-level suites if present
        "test_opensearchpy/test_server"
        "test_opensearchpy/test_server_secured"
      ];
      pythonImportsCheck = (old.pythonImportsCheck or []) ++ [ "opensearchpy" ];
    });
  });
}
