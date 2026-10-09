import 'dart:io' show SecurityContext;

import 'package:grpc/grpc.dart';

import 'errors.dart';
import 'gen/dys/v1/dys.pbgrpc.dart' as pb;
import 'paired_server.dart';
import 'transport.dart';

/// mTLS client for the main listener. Picks the first reachable host lazily and re-races all
/// hosts after a connection-level failure (e.g. moved from home Wi-Fi to Tailscale).
class DysClient {
  DysClient(
    this.server, {
    this.connectTimeout = const Duration(seconds: 4),
    this.callTimeout = const Duration(seconds: 5),
  });

  final PairedServer server;
  final Duration connectTimeout;
  final Duration callTimeout;

  ClientChannel? _channel;
  pb.SystemClient? _system;
  String? _host;

  /// Host currently in use, if connected.
  String? get host => _host;

  SecurityContext _ctx() => mtlsContext(caDer: server.caDer, certDer: server.certDer, keyPem: server.keyPem);

  Future<pb.SystemClient> _connect() async {
    if (_system != null) return _system!;
    final host = await firstReachable(server.hosts, server.mainPort, context: _ctx, timeout: connectTimeout);
    final ch = ClientChannel(host,
        port: server.mainPort, options: channelOptions(ContextCredentials(_ctx), connectTimeout: connectTimeout));
    _channel = ch;
    _host = host;
    return _system = pb.SystemClient(ch);
  }

  Future<T> _call<T>(Future<T> Function(pb.SystemClient s, CallOptions o) f, {Duration? timeout}) async {
    try {
      final s = await _connect();
      return await f(s, CallOptions(timeout: timeout ?? callTimeout));
    } catch (e) {
      final err = DysException.from(e, pairing: false);
      // Only connection-level problems warrant re-racing the hosts.
      if (const {DysErrorKind.unreachable, DysErrorKind.timeout, DysErrorKind.notAuthorized, DysErrorKind.other}
          .contains(err.kind)) {
        await _reset();
      }
      throw err;
    }
  }

  Future<pb.PingReply> ping() async {
    final r = await _call((s, o) => s.ping(pb.PingRequest(), options: o));
    _onLan = r.fromLan;
    return r;
  }

  /// Whether dysd sees the current connection as coming from the LAN (from the last Ping on this
  /// connection; null until known). dysd only allows applying updates from the LAN.
  bool? get onLan => _onLan;
  bool? _onLan;

  /// [onLan], pinging first if it isn't known for the current connection.
  Future<bool> isOnLan() async => _onLan ?? (await ping()).fromLan;

  Future<pb.GpuInfo> getGpu() => _call((s, o) => s.getGpu(pb.GetGpuRequest(), options: o));

  /// [watts] = 0 resets to the driver default and forgets the saved value.
  Future<pb.GpuInfo> setGpuPowerLimit(int watts) => _call(
      (s, o) => s.setGpuPowerLimit(pb.SetGpuPowerLimitRequest(watts: watts), options: o),
      timeout: const Duration(seconds: 20));

  Future<void> rebootToWindows() =>
      _call((s, o) => s.rebootToWindows(pb.RebootToWindowsRequest(confirm: true), options: o));

  /// Syncs a temporary copy of the package DBs on the PC unless cached, so allow it time.
  Future<pb.UpdateList> checkUpdates({bool force = false}) => _call(
      (s, o) => s.checkUpdates(pb.CheckUpdatesRequest(force: force), options: o),
      timeout: const Duration(minutes: 4));

  Future<pb.UpdateStatus> applyUpdates() =>
      _call((s, o) => s.applyUpdates(pb.ApplyUpdatesRequest(confirm: true), options: o),
          timeout: const Duration(seconds: 20));

  Future<pb.UpdateStatus> updateStatus({int logLines = 20}) =>
      _call((s, o) => s.getUpdateStatus(pb.GetUpdateStatusRequest(logLines: logLines), options: o));

  /// All OpenRGB devices plus the software effect names dysd offers. Polls OpenRGB on the PC.
  Future<pb.RgbDeviceList> listRgbDevices() =>
      _call((s, o) => s.listRgbDevices(pb.ListRgbDevicesRequest(), options: o), timeout: const Duration(seconds: 10));

  /// One solid colour (0xRRGGBB) on the whole device, or [off]. Stops a running software effect.
  Future<pb.RgbDevice> setRgbColor(int deviceId, int rgb, {bool off = false}) => _call(
    (s, o) => s.setRgbColor(
      pb.SetRgbColorRequest(deviceId: deviceId, rgb: rgb & 0xFFFFFF, off: off),
      options: o,
    ),
  );

  /// Switch to the device's own mode [modeIndex]. Null values keep the mode's current setting;
  /// setting something the mode doesn't support is `invalidInput`. Stops a running software effect.
  Future<pb.RgbDevice> setRgbMode(
    int deviceId,
    int modeIndex, {
    int? speed,
    int? brightness,
    int? direction,
    List<int>? colors,
  }) => _call(
    (s, o) => s.setRgbMode(
      pb.SetRgbModeRequest(
        deviceId: deviceId,
        modeIndex: modeIndex,
        speed: speed,
        brightness: brightness,
        direction: direction,
        colors: colors == null ? null : pb.RgbColors(rgb: colors.map((c) => c & 0xFFFFFF)),
      ),
      options: o,
    ),
  );

  /// Software effect run by dysd (one of [pb.RgbDeviceList.softwareEffects], or "none" to stop and
  /// keep the last frame). [speed] 1..10, [brightness] 1..100 %; 0 = dysd's default.
  Future<pb.RgbDevice> setRgbEffect(int deviceId, String effect, {int speed = 0, int brightness = 0, int? rgb}) =>
      _call(
        (s, o) => s.setRgbEffect(
          pb.SetRgbEffectRequest(
            deviceId: deviceId,
            effect: effect,
            speed: speed,
            brightness: brightness,
            rgb: rgb == null ? null : rgb & 0xFFFFFF,
          ),
          options: o,
        ),
      );

  Future<void> _reset() async {
    final ch = _channel;
    _channel = null;
    _system = null;
    _host = null;
    _onLan = null;
    await ch?.shutdown();
  }

  Future<void> close() => _reset();
}

/// Pings with the freshly paired credentials and checks the server sees our certificate.
Future<pb.PingReply> verifyPaired(PairedServer server) async {
  final client = DysClient(server);
  try {
    final reply = await client.ping();
    if (reply.clientFingerprint != server.fingerprint) {
      throw DysException(DysErrorKind.other,
          'server saw fingerprint ${reply.clientFingerprint}, expected ${server.fingerprint}');
    }
    return reply;
  } finally {
    await client.close();
  }
}
