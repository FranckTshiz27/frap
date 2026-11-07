import 'package:flutter/material.dart';
import 'package:mobile_fp/constants/app_assets.dart';
import 'package:mobile_fp/utils/asset_precache.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final decoded = AppAssetCache.logoImage;
    if (decoded != null) {
      return SizedBox(
        height: height,
        width: width,
        child: RawImage(
          image: decoded,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        ),
      );
    }

    final logoBytes = AppAssetCache.logoBytes;
    if (logoBytes != null) {
      return Image(
        image: MemoryImage(logoBytes),
        height: height,
        width: width,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      );
    }

    return Image.asset(
      AppAssets.appLogo,
      height: height,
      width: width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }
}
