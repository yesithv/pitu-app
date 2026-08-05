package com.ironcoding.pituapp

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (en vez de FlutterActivity) es requisito de local_auth
// para mostrar el prompt biométrico (RNF-11).
class MainActivity : FlutterFragmentActivity()
