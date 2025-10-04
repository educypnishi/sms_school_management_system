import 'package:flutter/material.dart';
import '../utils/enhanced_responsive_helper.dart';

class EnhancedResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool enableTouchFeedback;
  final VoidCallback? onTap;

  const EnhancedResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.enableTouchFeedback = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? EdgeInsets.all(
      EnhancedResponsiveHelper.getEnhancedResponsiveValue(
        context,
        smallMobile: 12.0,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );

    final responsiveMargin = margin ?? EdgeInsets.all(
      EnhancedResponsiveHelper.getEnhancedResponsiveValue(
        context,
        smallMobile: 8.0,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
      ),
    );

    final responsiveElevation = elevation ?? EnhancedResponsiveHelper.getEnhancedResponsiveValue(
      context,
      smallMobile: 2.0,
      mobile: 4.0,
      tablet: 6.0,
      desktop: 8.0,
    );

    final responsiveBorderRadius = borderRadius ?? BorderRadius.circular(
      EnhancedResponsiveHelper.getEnhancedResponsiveValue(
        context,
        smallMobile: 8.0,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
      ),
    );

    Widget cardWidget = Card(
      elevation: responsiveElevation,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: responsiveBorderRadius,
      ),
      margin: responsiveMargin,
      child: Padding(
        padding: responsivePadding,
        child: child,
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
        borderRadius: responsiveBorderRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
