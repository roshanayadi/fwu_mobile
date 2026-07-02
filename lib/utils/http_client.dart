import 'package:http/http.dart' as http;

/// Shared HTTP client factory for the FWU app.
/// All providers should use this to ensure consistent timeout and SSL behaviour.

const _defaultTimeout = Duration(seconds: 30);

/// Returns a plain [http.Client]. Add timeouts per-request via `.timeout()`.
http.Client createHttpClient() => http.Client();

/// Default request timeout used across the app.
Duration get defaultTimeout => _defaultTimeout;
