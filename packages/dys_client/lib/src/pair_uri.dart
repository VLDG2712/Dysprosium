// Parser for the pairing QR payload produced by dysd:
//   dys://pair?v=1&name=<host>&host=<h1>&host=<h2>&port=<pairing>&main=<main>&token=<32 hex>&sfp=<64 hex>
// Everything in it is untrusted input (anyone can print a QR code), so validate strictly.

class PairUriException implements Exception {
  PairUriException(this.message);
  final String message;
  @override
  String toString() => 'invalid pairing code: $message';
}

class PairUri {
  PairUri({
    required this.name,
    required this.hosts,
    required this.pairPort,
    required this.mainPort,
    required this.token,
    required this.sfp,
  });

  /// Server hostname (display only).
  final String name;

  /// Hosts to try, in dysd's preferred order. IPv6 literals without brackets.
  final List<String> hosts;
  final int pairPort;
  final int mainPort;

  /// One-time token, 32 lowercase hex chars.
  final String token;

  /// SHA-256 of the server leaf certificate (DER), 64 lowercase hex chars.
  final String sfp;

  static const maxHosts = 8;
  static final _hex32 = RegExp(r'^[0-9a-f]{32}$');
  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');
  // Hostname / IPv4 / IPv6 (after bracket stripping). Deliberately conservative.
  static final _host = RegExp(r'^[A-Za-z0-9.\-:%]{1,253}$');
  static final _name = RegExp(r'^[A-Za-z0-9.\-_]{1,64}$');

  static PairUri parse(String raw) {
    final text = raw.trim();
    final Uri uri;
    try {
      // Uri.parse rejects '[' ']' in the query, so percent-encode them first.
      uri = Uri.parse(text.replaceAll('[', '%5B').replaceAll(']', '%5D'));
    } on FormatException catch (e) {
      throw PairUriException(e.message);
    }
    if (uri.scheme != 'dys' || uri.host != 'pair') {
      throw PairUriException('not a dys://pair code');
    }
    final q = uri.queryParametersAll;

    String one(String key) {
      final v = q[key];
      if (v == null || v.length != 1) throw PairUriException('expected exactly one "$key"');
      return v.single;
    }

    int port(String key) {
      final p = int.tryParse(one(key));
      if (p == null || p < 1 || p > 65535) throw PairUriException('bad $key');
      return p;
    }

    if (one('v') != '1') throw PairUriException('unsupported version ${one('v')}');

    final name = one('name');
    if (!_name.hasMatch(name)) throw PairUriException('bad name');

    final hosts = <String>[];
    for (var h in q['host'] ?? const <String>[]) {
      if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
      if (!_host.hasMatch(h)) throw PairUriException('bad host');
      if (!hosts.contains(h)) hosts.add(h);
    }
    if (hosts.isEmpty) throw PairUriException('no host');
    if (hosts.length > maxHosts) throw PairUriException('too many hosts');

    final token = one('token');
    if (!_hex32.hasMatch(token)) throw PairUriException('bad token');
    final sfp = one('sfp');
    if (!_hex64.hasMatch(sfp)) throw PairUriException('bad sfp');

    return PairUri(
      name: name,
      hosts: hosts,
      pairPort: port('port'),
      mainPort: port('main'),
      token: token,
      sfp: sfp,
    );
  }
}
