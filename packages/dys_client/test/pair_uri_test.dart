import 'package:dys_client/dys_client.dart';
import 'package:test/test.dart';

const _tok = 'ab0123456789abcdef0123456789abcd';
const _sfp = '841381486058f838e28fb142ede3eda85f51835c0185408b4dd411a256ad0158';

String _uri({String v = '1', String hosts = 'host=192.168.2.56&host=europium.local', String extra = ''}) =>
    'dys://pair?v=$v&name=europium&$hosts&port=50052&main=50051&token=$_tok&sfp=$_sfp$extra';

void main() {
  test('parses dysd output incl. bracketed IPv6', () {
    final u = PairUri.parse(
        'dys://pair?v=1&name=europium&host=100.64.0.10&host=[fd7a::1]&host=europium.local&port=50052&main=50051&token=$_tok&sfp=$_sfp');
    expect(u.name, 'europium');
    expect(u.hosts, ['100.64.0.10', 'fd7a::1', 'europium.local']);
    expect(u.pairPort, 50052);
    expect(u.mainPort, 50051);
    expect(u.token, _tok);
    expect(u.sfp, _sfp);
  });

  test('tolerates surrounding whitespace and dedups hosts', () {
    final u = PairUri.parse('  ${_uri(hosts: 'host=a.b&host=a.b')}\n');
    expect(u.hosts, ['a.b']);
  });

  final bad = <String, String>{
    'wrong scheme': _uri().replaceFirst('dys://', 'https://'),
    'wrong action': _uri().replaceFirst('//pair', '//evil'),
    'version 2': _uri(v: '2'),
    'no hosts': _uri(hosts: 'x=1'),
    'host with path': _uri(hosts: 'host=evil.com/x'),
    'host with userinfo': _uri(hosts: 'host=a@b'),
    'too many hosts': _uri(hosts: List.generate(9, (i) => 'host=h$i').join('&')),
    'duplicate token': _uri(extra: '&token=$_tok'),
    'short token': _uri().replaceFirst(_tok, 'abcd'),
    'uppercase sfp': _uri().replaceFirst(_sfp, _sfp.toUpperCase()),
    'port 0': _uri().replaceFirst('port=50052', 'port=0'),
    'port too big': _uri().replaceFirst('main=50051', 'main=70000'),
    'garbage': 'hello',
  };
  bad.forEach((why, s) {
    test('rejects: $why', () => expect(() => PairUri.parse(s), throwsA(isA<PairUriException>())));
  });

  test('device name rule matches dysd', () {
    expect(isValidDeviceName('S24 Ultra (main)'), isTrue);
    expect(isValidDeviceName('a' * 64), isTrue);
    expect(isValidDeviceName('a' * 65), isFalse);
    expect(isValidDeviceName(''), isFalse);
    expect(isValidDeviceName('phöne'), isFalse);
    expect(isValidDeviceName('a;rm -rf'), isFalse);
  });
}
