import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnhancedResponsiveHelper {
  // Enhanced screen size breakpoints
  static const double smallMobileBreakpoint = 360;
  static const double mobileBreakpoint = 600;
  static const double largeMobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  static const double largeDesktopBreakpoint = 1920;
  
  // Get enhanced screen type
  static EnhancedScreenType getEnhancedScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < smallMobileBreakpoint) {
      return EnhancedScreenType.smallMobile;
    } else if (width < mobileBreakpoint) {
      return EnhancedScreenType.mobile;
    } else if (width < largeMobileBreakpoint) {
      return EnhancedScreenType.largeMobile;
    } else if (width < tabletBreakpoint) {
      return EnhancedScreenType.tablet;
    } else if (width < largeDesktopBreakpoint) {
      return EnhancedScreenType.desktop;
    } else {
      return EnhancedScreenType.largeDesktop;
    }
  }
  
  // Legacy compatibility
  static ScreenType getScreenType(BuildContext context) {
    final enhancedType = getEnhancedScreenType(context);
    switch (enhancedType) {
      case EnhancedScreenType.smallMobile:
      case EnhancedScreenType.mobile:
      case EnhancedScreenType.largeMobile:
        return ScreenType.mobile;
      case EnhancedScreenType.tablet:
        return ScreenType.tablet;
      case EnhancedScreenType.desktop:
      case EnhancedScreenType.largeDesktop:
        return ScreenType.desktop;
    }
  }
  
  // Device type checks
  static bool isSmallMobile(BuildContext context) {
    return getEnhancedScreenType(context) == EnhancedScreenType.smallMobile;
  }
  
  static bool isMobile(BuildContext context) {
    final type = getEnhancedScreenType(context);
    return type == EnhancedScreenType.smallMobile || 
           type == EnhancedScreenType.mobile || 
           type == EnhancedScreenType.largeMobile;
  }
  
  static bool isTablet(BuildContext context) {
    return getEnhancedScreenType(context) == EnhancedScreenType.tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    final type = getEnhancedScreenType(context);
    return type == EnhancedScreenType.desktop || 
           type == EnhancedScreenType.largeDesktop;
  }
  
  // Orientation helpers
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  // Safe area helpers
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  // Enhanced responsive value with more granular control
  static T getEnhancedResponsiveValue<T>(
    BuildContext context, {
    required T smallMobile,
    T? mobile,
    T? largeMobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final screenType = getEnhancedScreenType(context);
    
    switch (screenType) {
      case EnhancedScreenType.smallMobile:
        return smallMobile;
      case EnhancedScreenType.mobile:
        return mobile ?? smallMobile;
      case EnhancedScreenType.largeMobile:
        return largeMobile ?? mobile ?? smallMobile;
      case EnhancedScreenType.tablet:
        return tablet ?? largeMobile ?? mobile ?? smallMobile;
      case EnhancedScreenType.desktop:
        return desktop ?? tablet ?? largeMobile ?? mobile ?? smallMobile;
      case EnhancedScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? largeMobile ?? mobile ?? smallMobile;
    }
  }
  
  // Legacy responsive value for backward compatibility
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return getEnhancedResponsiveValue(
      context,
      smallMobile: mobile,
      mobile: mobile,
      largeMobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: desktop,
    );
  }
  
  // Enhanced responsive padding with orientation support
  static EdgeInsets getEnhancedResponsivePadding(BuildContext context) {
    final isPortraitMode = isPortrait(context);
    final safeArea = getSafeAreaPadding(context);
    
    return getEnhancedResponsiveValue(
      context,
      smallMobile: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        top: 8.0 + safeArea.top,
        bottom: 8.0 + safeArea.bottom,
      ),
      mobile: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0 + safeArea.top,
        bottom: 12.0 + safeArea.bottom,
      ),
      largeMobile: EdgeInsets.only(
        left: isPortraitMode ? 20.0 : 32.0,
        right: isPortraitMode ? 20.0 : 32.0,
        top: 16.0 + safeArea.top,
        bottom: 16.0 + safeArea.bottom,
      ),
      tablet: EdgeInsets.only(
        left: isPortraitMode ? 24.0 : 48.0,
        right: isPortraitMode ? 24.0 : 48.0,
        top: 20.0 + safeArea.top,
        bottom: 20.0 + safeArea.bottom,
      ),
      desktop: EdgeInsets.only(
        left: 32.0,
        right: 32.0,
        top: 24.0 + safeArea.top,
        bottom: 24.0 + safeArea.bottom,
      ),
    );
  }
  
  // Touch-friendly sizing
  static double getTouchFriendlySize(BuildContext context, double baseSize) {
    return getEnhancedResponsiveValue(
      context,
      smallMobile: baseSize * 1.2, // Larger for small screens
      mobile: baseSize * 1.1,
      largeMobile: baseSize,
      tablet: baseSize * 0.9,
      desktop: baseSize * 0.8,
    );
  }
  
  // Minimum touch target size (44px for iOS, 48px for Android)
  static double getMinTouchTarget(BuildContext context) {
    return getEnhancedResponsiveValue(
      context,
      smallMobile: 48.0,
      mobile: 48.0,
      largeMobile: 44.0,
      tablet: 44.0,
      desktop: 40.0,
    );
  }
  
  // Enhanced font sizing with accessibility
  static double getEnhancedFontSize(
    BuildContext context, {
    required double baseFontSize,
    bool respectAccessibility = true,
  }) {
    double fontSize = getEnhancedResponsiveValue(
      context,
      smallMobile: baseFontSize * 1.1,
      mobile: baseFontSize,
      largeMobile: baseFontSize * 1.05,
      tablet: baseFontSize * 1.1,
      desktop: baseFontSize * 1.2,
    );
    
    if (respectAccessibility) {
      final textScaleFactor = MediaQuery.of(context).textScaleFactor;
      fontSize *= textScaleFactor.clamp(0.8, 1.3); // Reasonable limits
    }
    
    return fontSize;
  }
  
  // Grid columns with enhanced breakpoints
  static int getEnhancedGridColumns(BuildContext context) {
    return getEnhancedResponsiveValue(
      context,
      smallMobile: 1,
      mobile: 2,
      largeMobile: 2,
      tablet: isPortrait(context) ? 2 : 3,
      desktop: 4,
      largeDesktop: 5,
    );
  }
  
  // Card width with maximum constraints
  static double getEnhancedCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCardWidth = getEnhancedResponsiveValue(
      context,
      smallMobile: 400.0,
      mobile: 500.0,
      largeMobile: 600.0,
      tablet: 700.0,
      desktop: 800.0,
    );
    
    return getEnhancedResponsiveValue(
      context,
      smallMobile: screenWidth - 24,
      mobile: (screenWidth - 32).clamp(0, maxCardWidth),
      largeMobile: (screenWidth - 40).clamp(0, maxCardWidth),
      tablet: (screenWidth - 48).clamp(0, maxCardWidth),
      desktop: (screenWidth * 0.8).clamp(0, maxCardWidth),
    );
  }
  
  // Navigation drawer width
  static double getNavigationDrawerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return getEnhancedResponsiveValue(
      context,
      smallMobile: screenWidth * 0.85,
      mobile: screenWidth * 0.80,
      largeMobile: 320.0,
      tablet: 350.0,
      desktop: 280.0,
    );
  }
  
  // App bar height with safe area
  static double getEnhancedAppBarHeight(BuildContext context) {
    final safeAreaTop = getStatusBarHeight(context);
    
    return getEnhancedResponsiveValue(
      context,
      smallMobile: kToolbarHeight + safeAreaTop,
      mobile: kToolbarHeight + safeAreaTop,
      largeMobile: (kToolbarHeight + 4) + safeAreaTop,
      tablet: (kToolbarHeight + 8) + safeAreaTop,
      desktop: (kToolbarHeight + 12) + safeAreaTop,
    );
  }
  
  // Bottom navigation height
  static double getBottomNavigationHeight(BuildContext context) {
    final safeAreaBottom = getBottomSafeArea(context);
    
    return getEnhancedResponsiveValue(
      context,
      smallMobile: 60.0 + safeAreaBottom,
      mobile: 65.0 + safeAreaBottom,
      largeMobile: 70.0 + safeAreaBottom,
      tablet: 75.0 + safeAreaBottom,
      desktop: 80.0 + safeAreaBottom,
    );
  }
  
  // Haptic feedback for mobile devices
  static void provideTouchFeedback(BuildContext context) {
    if (isMobile(context)) {
      HapticFeedback.lightImpact();
    }
  }
  
  // Heavy haptic feedback for important actions
  static void provideHeavyFeedback(BuildContext context) {
    if (isMobile(context)) {
      HapticFeedback.heavyImpact();
    }
  }
  
  // Selection feedback
  static void provideSelectionFeedback(BuildContext context) {
    if (isMobile(context)) {
      HapticFeedback.selectionClick();
    }
  }
}

enum EnhancedScreenType {
  smallMobile,  // < 360px
  mobile,       // 360px - 600px
  largeMobile,  // 600px - 768px
  tablet,       // 768px - 1024px
  desktop,      // 1024px - 1920px
  largeDesktop, // > 1920px
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}

// Enhanced responsive layout widget
class EnhancedResponsiveLayout extends StatelessWidget {
  final Widget smallMobile;
  final Widget? mobile;
  final Widget? largeMobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  
  const EnhancedResponsiveLayout({
    super.key,
    required this.smallMobile,
    this.mobile,
    this.largeMobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final screenType = EnhancedResponsiveHelper.getEnhancedScreenType(context);
    
    switch (screenType) {
      case EnhancedScreenType.smallMobile:
        return smallMobile;
      case EnhancedScreenType.mobile:
        return mobile ?? smallMobile;
      case EnhancedScreenType.largeMobile:
        return largeMobile ?? mobile ?? smallMobile;
      case EnhancedScreenType.tablet:
        return tablet ?? largeMobile ?? mobile ?? smallMobile;
      case EnhancedScreenType.desktop:
        return desktop ?? tablet ?? largeMobile ?? mobile ?? smallMobile;
      case EnhancedScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? largeMobile ?? mobile ?? smallMobile;
    }
  }
}

// Legacy responsive layout for backward compatibility
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return EnhancedResponsiveLayout(
      smallMobile: mobile,
      mobile: mobile,
      largeMobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: desktop,
    );
  }
}

// Enhanced responsive card widget
class EnhancedResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? color;
  final bool enableTouchFeedback;
  final VoidCallback? onTap;
  
  const EnhancedResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.enableTouchFeedback = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? EnhancedResponsiveHelper.getEnhancedResponsivePadding(context);
    final borderRadius = EnhancedResponsiveHelper.getEnhancedResponsiveValue(
      context,
      smallMobile: 8.0,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
    
    Widget cardWidget = Container(
      margin: margin,
      child: Card(
        elevation: elevation ?? 4.0,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: responsivePadding,
          child: child,
        ),
      ),
    );
    
    if (onTap != null) {
      cardWidget = InkWell(
        onTap: () {
          if (enableTouchFeedback) {
            EnhancedResponsiveHelper.provideTouchFeedback(context);
          }
          onTap!();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
}

// Enhanced responsive text widget
class EnhancedResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? baseFontSize;
  final bool respectAccessibility;
  
  const EnhancedResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.baseFontSize,
    this.respectAccessibility = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final fontSize = baseFontSize != null 
        ? EnhancedResponsiveHelper.getEnhancedFontSize(
            context, 
            baseFontSize: baseFontSize!,
            respectAccessibility: respectAccessibility,
          )
        : null;
    
    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// Enhanced responsive button widget
class EnhancedResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final bool enableHapticFeedback;
  final bool isDestructive;
  
  const EnhancedResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.enableHapticFeedback = true,
    this.isDestructive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final minTouchTarget = EnhancedResponsiveHelper.getMinTouchTarget(context);
    final fontSize = EnhancedResponsiveHelper.getEnhancedFontSize(context, baseFontSize: 16.0);
    final borderRadius = EnhancedResponsiveHelper.getEnhancedResponsiveValue(
      context,
      smallMobile: 8.0,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
    
    final buttonStyle = style ?? ElevatedButton.styleFrom(
      minimumSize: Size(double.infinity, minTouchTarget),
      textStyle: TextStyle(fontSize: fontSize),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    
    void handlePress() {
      if (enableHapticFeedback) {
        if (isDestructive) {
          EnhancedResponsiveHelper.provideHeavyFeedback(context);
        } else {
          EnhancedResponsiveHelper.provideTouchFeedback(context);
        }
      }
      onPressed?.call();
    }
    
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : handlePress,
        icon: isLoading ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ) : icon!,
        label: Text(text),
        style: buttonStyle,
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : handlePress,
      style: buttonStyle,
      child: isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }
}
