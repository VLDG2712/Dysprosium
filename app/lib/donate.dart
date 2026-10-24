import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Donation links shown at the bottom of Settings.
///
/// Off for store builds that don't allow donation links to individuals (Google Play only allows
/// validated charities): `flutter build apk --dart-define=DONATIONS=false`.
const donationsEnabled = bool.fromEnvironment('DONATIONS', defaultValue: true);

/// GitHub user receiving GitHub Sponsors (must be enrolled at github.com/sponsors).
const githubSponsorsUser = 'VLDG2712';

/// paypal.me handle (the part after paypal.me/). Empty = no PayPal button.
/// Can also be set at build time: --dart-define=PAYPAL_ME=yourname
const paypalMeHandle = String.fromEnvironment('PAYPAL_ME');

class DonationLink {
  const DonationLink({required this.id, required this.label, required this.detail, required this.icon, required this.url});

  final String id;
  final String label;
  final String detail;
  final IconData icon;
  final Uri url;
}

List<DonationLink> defaultDonationLinks({String github = githubSponsorsUser, String paypal = paypalMeHandle}) => [
      if (github.isNotEmpty)
        DonationLink(
          id: 'github',
          label: 'GitHub Sponsors',
          detail: 'One-off or monthly; GitHub takes no fee',
          icon: Icons.favorite_outline,
          url: Uri.https('github.com', '/sponsors/$github'),
        ),
      if (paypal.isNotEmpty)
        DonationLink(
          id: 'paypal',
          label: 'PayPal',
          detail: 'One-off, any amount',
          icon: Icons.payments_outlined,
          url: Uri.https('paypal.me', '/$paypal'),
        ),
    ];

/// Opens a link in the browser (or the matching app). Returns false if nothing could open it.
typedef UrlOpener = Future<bool> Function(Uri url);

Future<bool> openExternally(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// The Settings section. Renders nothing when donations are off or no link is configured.
class SupportSection extends StatelessWidget {
  const SupportSection({super.key, required this.links, this.open = openExternally});

  final List<DonationLink> links;
  final UrlOpener open;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text('Support Dysprosium',
            style: t.textTheme.titleSmall?.copyWith(color: t.colorScheme.primary)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Text(
          "If you find Dysprosium useful and want to chip in, here's how. "
          'Nothing in the app depends on it.',
          style: t.textTheme.bodyMedium,
        ),
      ),
      for (final l in links)
        ListTile(
          key: ValueKey('donate-${l.id}'),
          leading: Icon(l.icon),
          title: Text(l.label),
          subtitle: Text(l.detail),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () async {
            final ok = await open(l.url);
            if (!ok && context.mounted) {
              ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(SnackBar(content: Text('Could not open ${l.url}')));
            }
          },
        ),
    ]);
  }
}
