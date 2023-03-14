import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'colour_scheme.dart';
import 'globals.dart';

import 'login.dart';
import 'timetable.dart';
import 'homework.dart';
import 'dashboard.dart';
import 'calendar.dart';
import 'exams.dart';
import 'classes.dart';
import 'notifs.dart';

Future<void> main() async {
  // This tells Flutter to start the app and render stuff.
  await setupNotifications();
  runApp(const PlanAway());
}

class PlanAway extends StatelessWidget {
  const PlanAway({Key? key}) : super(key: key);

  // This overrides the build function, and returns a MaterialApp.
  // The MaterialApp is responsible for all rendering and event handling.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanAway',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
      ),
      navigatorKey: navigatorKey,
      // I create routes here, which allows me to change the page by pushing the route's name
      // instead of using the class.
      routes: {
        '/': (context) => const LoginPage(),
        '/dash': (context) => const MainPage(),
      },
      initialRoute: '/',
    );
  }
}

/// The main page (Dashboard) for PlanAway
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  // As this widget is stateful (it has a state),
  // The createState function is needed so that it can be called
  // Every time the widget (whole app in this case) needs to be re-rendered.
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  // This simply creates the TabController on startup.
  @override
  void initState() {
    tabController = TabController(
      vsync: this,
      length: 5,
      initialIndex: initialTabIndex,
    );
    super.initState();
  }

  // And this disposes of the TabController on close.
  @override
  void dispose() {
    tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    currentScaffoldKey = mainScaffoldKey;
    return Scaffold(
      key: mainScaffoldKey,
      body: TabBarView(
        controller: tabController,
        physics: const BouncingScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
        children: [
          const TimetablePage(),
          const HomeworkPage(),
          const Dashboard(),
          const CalendarPage(),
          me!.permissions == Permissions.user
              ? const ExamPage()
              : const ClassPage(), // We switch out the marks page with a page
          // For managing classes for teacher accounts.
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: TabBar(
          controller: tabController,
          unselectedLabelColor: Theme.of(context).colorScheme.outline,
          unselectedLabelStyle: const TextStyle(
            // Since some browsers don't like a font size of 0, I have used
            // 0.01 to hide the text when it's not selected.
            fontSize: 0.01,
          ),
          labelColor: Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          // These tabs correspond to the pages in the TabBarView
          tabs: <Widget>[
            const Tooltip(
              message: 'Timetable',
              child: Tab(
                icon: Icon(
                  Icons.calendar_today,
                  semanticLabel: 'Timetable',
                ),
                child: AutoSizeText(
                  'Timetable',
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            const Tooltip(
              message: 'Homework',
              child: Tab(
                icon: Icon(
                  Icons.book,
                  semanticLabel: 'Homework',
                ),
                child: AutoSizeText(
                  'Homework',
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            const Tooltip(
              message: 'Dashboard',
              child: Tab(
                icon: Icon(
                  Icons.home,
                  semanticLabel: 'Dashboard',
                ),
                child: AutoSizeText(
                  'Dashboard',
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            const Tooltip(
              message: 'Calendar',
              child: Tab(
                icon: Icon(
                  Icons.calendar_month,
                  semanticLabel: 'Calendar',
                ),
                child: AutoSizeText(
                  'Calendar',
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            me!.permissions == Permissions.user
                ? const Tooltip(
                    message: 'Exams',
                    child: Tab(
                      icon: Icon(
                        Icons.check_circle_outline,
                        semanticLabel: 'Exams',
                      ),
                      child: AutoSizeText(
                        'Exams',
                        maxLines: 1,
                        minFontSize: 0,
                        maxFontSize: 16,
                      ),
                    ),
                  )
                : const Tooltip(
                    message: 'Classes',
                    child: Tab(
                      icon: Icon(
                        Icons.school,
                        semanticLabel: 'Classes',
                      ),
                      child: AutoSizeText(
                        'Classes',
                        maxLines: 1,
                        minFontSize: 0,
                        maxFontSize: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
