import 'package:flutter/material.dart';

// const double kPaddingSmall = 8;
// const double kPaddingMedium = 16;
// const double paddingLarge = 24;

class AppSizes {
  // Padding and Margin
  static const double paddingXXS = 4.0;
  static const double paddingXS = 8.0;
  static const double paddingS = 12.0;
  static const double paddingM = 16.0;
  static const double paddingL = 20.0;
  static const double paddingXL = 24.0;
  static const double paddingXXL = 32.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // Icon Sizes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 40.0;

  // Button Sizes
  static const double buttonHeightS = 40.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // Text Sizes
  static const double textSizeXS = 12.0;
  static const double textSizeS = 14.0;
  static const double textSizeM = 16.0;
  static const double textSizeL = 18.0;
  static const double textSizeXL = 20.0;
  static const double textSize22 = 22.0;
  static const double textSizeXXL = 24.0;

  // App Bar Sizes
  static const double appBarHeight = 56.0;

  // Divider Sizes
  static const double dividerThickness = 1.0;

  // Custom Sizes
  static const double avatarSize = 48.0;
  static const double cardElevation = 2.0;
}

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late double defaultSize;
  static Orientation? orientation;

  static double get defaultPadding => defaultSize * 1.5;

  void init(BoxConstraints constraints, Orientation orientation) {
    screenWidth = constraints.maxWidth;
    screenHeight = constraints.maxHeight;
    //Apple iPhone 11 viewport size is 414 x 896 (px)
    //With iPhone 11, i set defaultSize = 10;
    //So if the screen increase or decrease then our defaultSize also vary
    if (orientation == Orientation.portrait) {
      defaultSize = screenHeight * 10 / 896;
    } else {
      defaultSize = screenHeight * 10 / 414;
    }
  }

  ///Singleton factory
  static final SizeConfig _instance = SizeConfig._internal();

  factory SizeConfig() {
    return _instance;
  }

  SizeConfig._internal();
}

class AppPadding {
  static const EdgeInsets paddingAllXXS = EdgeInsets.all(AppSizes.paddingXXS);
  static const EdgeInsets paddingAllXS = EdgeInsets.all(AppSizes.paddingXS);
  static const EdgeInsets paddingAllS = EdgeInsets.all(AppSizes.paddingS);
  static const EdgeInsets paddingAllM = EdgeInsets.all(AppSizes.paddingM);
  static const EdgeInsets paddingAllL = EdgeInsets.all(AppSizes.paddingL);
  static const EdgeInsets paddingAllXL = EdgeInsets.all(AppSizes.paddingXL);
  static const EdgeInsets paddingAllXXL = EdgeInsets.all(AppSizes.paddingXXL);

  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(
    horizontal: AppSizes.paddingXS,
  );
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(
    horizontal: AppSizes.paddingS,
  );
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(
    horizontal: AppSizes.paddingM,
  );
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(
    horizontal: AppSizes.paddingL,
  );
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(
    horizontal: AppSizes.paddingXL,
  );

  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(
    vertical: AppSizes.paddingXS,
  );
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(
    vertical: AppSizes.paddingS,
  );
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(
    vertical: AppSizes.paddingM,
  );
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(
    vertical: AppSizes.paddingL,
  );
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(
    vertical: AppSizes.paddingXL,
  );
}

class AppRadius {
  static const BorderRadius radiusAllXS = BorderRadius.all(
    Radius.circular(AppSizes.radiusXS),
  );
  static const BorderRadius radiusAllS = BorderRadius.all(
    Radius.circular(AppSizes.radiusS),
  );
  static const BorderRadius radiusAllM = BorderRadius.all(
    Radius.circular(AppSizes.radiusM),
  );
  static const BorderRadius radiusAllL = BorderRadius.all(
    Radius.circular(AppSizes.radiusL),
  );
  static const BorderRadius radiusAllXL = BorderRadius.all(
    Radius.circular(AppSizes.radiusXL),
  );
  static const BorderRadius radiusAllXXL = BorderRadius.all(
    Radius.circular(AppSizes.radiusXXL),
  );
}
