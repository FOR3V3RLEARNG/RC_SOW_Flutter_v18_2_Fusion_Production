import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/app.dart';
import 'package:rc_sow_connected/core/routes.dart';

void main() {
  test('every declared screen route resolves', () {
    for (final routeName in RcRoutes.all) {
      final route = buildRcRoute(RouteSettings(name: routeName));
      expect(route, isA<MaterialPageRoute<dynamic>>(), reason: routeName);
    }
  });


  test('OAuth callback routes normalize to the splash route', () {
    expect(normalizeRcRouteName('/?code=pkce-code'), RcRoutes.splash);
    expect(
      normalizeRcRouteName(
        'org.jamaicaredcross.rcsowflutter://login-callback?code=pkce-code',
      ),
      RcRoutes.splash,
    );
    expect(
      normalizeRcRouteName('/settings?source=notification'),
      RcRoutes.settings,
    );
  });

  test('unknown route resolves to the recovery screen', () {
    final route = buildRcRoute(
      const RouteSettings(name: '/missing'),
    ) as MaterialPageRoute<dynamic>;
    expect(route.settings.name, '/missing');
  });
}
