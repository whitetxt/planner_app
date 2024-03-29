import 'package:flutter/material.dart';

import 'settings.dart';

class PLAppBar extends PreferredSize {
  PLAppBar(this.text, this.context, {Key? key})
      : super(
          key: key,
          // Lock the height of the appbar to 48 pixels.
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Theme.of(context).colorScheme.background,
            title: Flex(
              // Since we want to have both the button and text on the appbar,
              // I use a Flex to include space between them.
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(text),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).highlightColor,
                    side: const BorderSide(width: 0),
                    shape: const CircleBorder(
                      side: BorderSide(width: 2),
                    ),
                  ),
                  child: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    // While normally I would user Navigator.pushNamed, here I
                    // wanted to have an animation, which pushNamed does not allow.
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).chain(
                              CurveTween(curve: Curves.easeOutSine),
                            ),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

  final String text;
  final BuildContext context;
}
