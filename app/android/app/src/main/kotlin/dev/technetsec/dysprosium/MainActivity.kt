package dev.technetsec.dysprosium

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity): local_auth needs a FragmentActivity for the
// fingerprint prompt.
class MainActivity : FlutterFragmentActivity()
