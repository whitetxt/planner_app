import "package:flutter/material.dart";

import "settings.dart";

class PLAppBar extends PreferredSize {
  PLAppBar(this.text, this.context, {Key? key})
      : super(
          key: key,
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            title: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(text),
                ElevatedButton(
                  clipBehavior: Clip.antiAlias,
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).highlightColor,
                    shape: const CircleBorder(
                      side: BorderSide(width: 2),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF000000),
                  ),
                  onPressed: () => Navigator.push(
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