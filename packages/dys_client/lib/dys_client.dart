/// Phone-side core for Dysprosium: pairing (QR → key + CSR → pinned Pair RPC) and the mTLS client.
library;

export 'src/client.dart' show DysClient, verifyPaired;
export 'src/errors.dart' show DysErrorKind, DysException;
export 'src/gen/dys/v1/dys.pb.dart' show PingReply;
export 'src/keys.dart' show DeviceKey;
export 'src/pair_uri.dart' show PairUri, PairUriException;
export 'src/paired_server.dart' show PairedServer;
export 'src/pairing.dart' show isValidDeviceName, pair;
