use serde_json::Value;

#[test]
fn local_webview_csp_is_enabled_and_restrictive() {
    let config: Value = serde_json::from_str(include_str!("../tauri.conf.json")).unwrap();
    let csp = config["app"]["security"]["csp"].as_str().expect("CSP must be a string");

    for directive in [
        "default-src 'self'",
        "base-uri 'self'",
        "object-src 'none'",
        "script-src 'self'",
        "style-src 'self' 'unsafe-inline'",
        "connect-src 'self' ipc: http://ipc.localhost",
    ] {
        assert!(csp.contains(directive), "CSP is missing {directive:?}");
    }
    assert!(!csp.contains("connect-src *"));
}

// macOS refuses LAN connections from an app that does not declare why it needs
// the local network, and keeps no privacy permission for an unsigned bundle.
#[test]
fn macos_bundle_can_reach_a_server_on_the_local_network() {
    let plist = include_str!("../Info.plist");
    assert!(plist.contains("<key>NSLocalNetworkUsageDescription</key>"));

    let config: Value = serde_json::from_str(include_str!("../tauri.conf.json")).unwrap();
    assert_eq!(config["bundle"]["macOS"]["signingIdentity"], "-");
}

#[test]
fn bundles_localized_network_permission_descriptions() {
    let config: Value = serde_json::from_str(include_str!("../tauri.conf.json")).unwrap();
    for locale in ["en", "vi"] {
        let destination = format!("Resources/{locale}.lproj/InfoPlist.strings");
        let source = config["bundle"]["macOS"]["files"][&destination]
            .as_str()
            .expect("localized InfoPlist is mapped into the macOS bundle");
        let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join(source);
        let contents = std::fs::read_to_string(path).expect("mapped localization file exists");
        assert!(contents.contains("NSLocalNetworkUsageDescription"));
        assert!(contents.contains(if locale == "vi" { "máy chủ Sure" } else { "Sure server" }));
    }
}
