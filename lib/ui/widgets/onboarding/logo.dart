import 'package:flutter/material.dart';

import '../../../theme.dart';

class Logo extends StatelessWidget {
  const Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
        child: isLightTheme(context)
            ? Image.asset('assets/logo.png', fit: BoxFit.fill, height: 126)
            : Image.asset('assets/logo_dark.png',
                fit: BoxFit.fill, height: 126));
  }
}
