/// Small formatting helpers shared by the cards.
library;

String bytes(num b) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '${v.round()} ${units[i]}' : '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}

/// Bytes per second as bits per second (what people compare against their line speed).
String bitrate(num bytesPerSec) {
  final bits = bytesPerSec * 8;
  if (bits < 1000) return '${bits.round()} b/s';
  if (bits < 1e6) return '${(bits / 1e3).toStringAsFixed(bits < 1e4 ? 1 : 0)} kb/s';
  if (bits < 1e9) return '${(bits / 1e6).toStringAsFixed(bits < 1e7 ? 1 : 0)} Mb/s';
  return '${(bits / 1e9).toStringAsFixed(2)} Gb/s';
}

String duration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}

/// "5m ago" for a unix timestamp (seconds).
String ago(int unix, {DateTime? now}) {
  if (unix <= 0) return '?';
  final n = now ?? DateTime.now();
  final d = n.difference(DateTime.fromMillisecondsSinceEpoch(unix * 1000));
  return d.isNegative ? 'just now' : '${duration(d)} ago';
}

String temp(double? c) => c == null ? '–' : '${c.toStringAsFixed(0)} °C';
