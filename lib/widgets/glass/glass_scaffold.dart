import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/glass_theme.dart';
import '../app_background_pattern.dart';
import 'glass_app_bar.dart';

class GlassScaffold extends StatelessWidget {
  final Widget? body;
  final String? title;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GlassScaffold({
    super.key,
    this.body,
    this.title,
    this.bottomNavigationBar,
    this.extendBody = true,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;

        return Scaffold(
          extendBody: extendBody,
          backgroundColor: GlassTheme.background(isDark),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Dynamic Background
              Container(color: GlassTheme.background(isDark)),

              // 2. Pattern Overlay
              AppBackgroundPattern(
                patternColor: isDark ? Colors.white : Colors.black,
                opacity: isDark ? 0.05 : 0.03,
              ),

              // 3. Content with AppBar
              SafeArea(
                bottom: !extendBody,
                child: Column(
                  children: [
                    if (title != null)
                      GlassAppBar(
                        title: title!,
                        isDark: isDark,
                        actions: actions,
                        leading: leading,
                        automaticallyImplyLeading: automaticallyImplyLeading,
                      ),
                    if (body != null) Expanded(child: body!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
