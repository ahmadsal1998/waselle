import 'package:flutter/material.dart';

/// A responsive button utility that ensures consistent button styling
/// across different screen sizes and languages
class ResponsiveButton {
  /// Get responsive padding based on screen width
  static EdgeInsets getPadding(BuildContext context, {
    double? horizontalMultiplier,
    double? verticalMultiplier,
    double? minHorizontal,
    double? maxHorizontal,
    double? minVertical,
    double? maxVertical,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Base padding values
    final baseHorizontal = horizontalMultiplier ?? 0.06; // 6% of screen width
    final baseVertical = verticalMultiplier ?? 0.02; // 2% of screen height
    
    // Calculate responsive padding
    double horizontal = screenWidth * baseHorizontal;
    double vertical = screenHeight * baseVertical;
    
    // Apply min/max constraints
    horizontal = horizontal.clamp(
      minHorizontal ?? 16.0,
      maxHorizontal ?? 32.0,
    );
    vertical = vertical.clamp(
      minVertical ?? 12.0,
      maxVertical ?? 20.0,
    );
    
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// Get responsive font size based on screen width
  static double getFontSize(BuildContext context, {
    double? baseSize,
    double? minSize,
    double? maxSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final base = baseSize ?? 16.0;
    final min = minSize ?? 14.0;
    final max = maxSize ?? 18.0;
    
    // Scale font size based on screen width (reference: 360dp base)
    final scaleFactor = screenWidth / 360.0;
    final fontSize = base * scaleFactor.clamp(0.9, 1.1);
    
    return fontSize.clamp(min, max);
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {
    double? baseSize,
    double? minSize,
    double? maxSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final base = baseSize ?? 18.0;
    final min = minSize ?? 16.0;
    final max = maxSize ?? 22.0;
    
    final scaleFactor = screenWidth / 360.0;
    final iconSize = base * scaleFactor.clamp(0.9, 1.1);
    
    return iconSize.clamp(min, max);
  }

  /// Create a responsive ElevatedButton with proper text overflow handling
  static Widget elevated({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
    double? borderRadius,
    IconData? icon,
    bool isFullWidth = true,
    double? minWidth,
  }) {
    final theme = Theme.of(context);
    final responsivePadding = padding ?? getPadding(context);
    final fontSize = getFontSize(context);
    final iconSize = getIconSize(context);
    
    Widget buttonContent = child;
    if (icon != null && child is Text) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Flexible(
            child: child,
          ),
        ],
      );
    }
    
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: minWidth != null ? Size(minWidth, 0) : null,
      ),
      child: buttonContent,
    );
    
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }

  /// Create a responsive OutlinedButton with proper text overflow handling
  static Widget outlined({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    Color? foregroundColor,
    Color? borderColor,
    EdgeInsets? padding,
    double? borderRadius,
    IconData? icon,
    bool isFullWidth = true,
    double? minWidth,
  }) {
    final theme = Theme.of(context);
    final responsivePadding = padding ?? getPadding(context);
    final fontSize = getFontSize(context);
    final iconSize = getIconSize(context);
    
    Widget buttonContent = child;
    if (icon != null && child is Text) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Flexible(
            child: child,
          ),
        ],
      );
    }
    
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? theme.colorScheme.primary,
        padding: responsivePadding,
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: minWidth != null ? Size(minWidth, 0) : null,
      ),
      child: buttonContent,
    );
    
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }

  /// Create a responsive TextButton with proper text overflow handling
  static Widget text({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    Color? foregroundColor,
    EdgeInsets? padding,
    double? borderRadius,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    final responsivePadding = padding ?? getPadding(
      context,
      horizontalMultiplier: 0.04,
      verticalMultiplier: 0.015,
    );
    final fontSize = getFontSize(context, baseSize: 14.0);
    final iconSize = getIconSize(context, baseSize: 16.0);
    
    Widget buttonContent = child;
    if (icon != null && child is Text) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 6),
          Flexible(
            child: child,
          ),
        ],
      );
    }
    
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? theme.colorScheme.primary,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: buttonContent,
    );
    
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }

  /// Create a responsive FilledButton with proper text overflow handling
  static Widget filled({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
    double? borderRadius,
    IconData? icon,
    bool isFullWidth = true,
    double? minWidth,
  }) {
    final theme = Theme.of(context);
    final responsivePadding = padding ?? getPadding(context);
    final fontSize = getFontSize(context);
    final iconSize = getIconSize(context);
    
    Widget buttonContent = child;
    if (icon != null && child is Text) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Flexible(
            child: child,
          ),
        ],
      );
    }
    
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: minWidth != null ? Size(minWidth, 0) : null,
      ),
      child: buttonContent,
    );
    
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
}

/// Extension methods for easier button creation
extension ResponsiveButtonExtension on BuildContext {
  ResponsiveButton get responsiveButton => ResponsiveButton();
}

