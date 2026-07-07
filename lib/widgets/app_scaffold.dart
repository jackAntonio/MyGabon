import 'package:flutter/material.dart';
import 'gradient_background.dart';

/// Remplace `Scaffold` sur chaque écran : applique le dégradé de fond doux
/// unifié de l'app (voir [GradientBackground]) derrière un Scaffold rendu
/// transparent. Expose les mêmes paramètres que [Scaffold] pour un
/// remplacement direct, sans dupliquer la logique de fond sur chaque page.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;
  final Widget? drawer;
  final Widget? endDrawer;

  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.resizeToAvoidBottomInset,
    this.drawer,
    this.endDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        extendBody: extendBody,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
    );
  }
}
