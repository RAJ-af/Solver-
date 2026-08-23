import 'package:flutter/material.dart';

import '../screens/solution_screen.dart';

/// Photo-pick ke baad SolutionScreen tak ka custom transition:
/// slide-up + fade, 300ms, easeOutCubic.
class SolutionRoute extends PageRouteBuilder {
  SolutionRoute(String imagePath)
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => SolutionScreen(imagePath: imagePath),
          settings: RouteSettings(arguments: imagePath),
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
}
