import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors.accent.withAlpha((255 * 0.05).round()),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.colors.surface.withAlpha((255 * 0.85).round()),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.colors.surfaceLight.withAlpha((255 * 0.6).round()),
                  AppTheme.colors.surface.withAlpha((255 * 0.9).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
              border: Border.all(
                color: Colors.white.withAlpha((255 * 0.1).round()),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
