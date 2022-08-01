import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import "timetable.dart";
import "homework.dart";
import "settings.dart";

void main() {
  // This tells flutter to start the app and render stuff.
  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({Key? key}) : super(key: key);

  // This overrides the build function, and returns a MaterialApp.
  // The MaterialApp is responsible for all rendering and event handling.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.grey.shade600,
        highlightColor: Colors.blue.shade100,
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey.shade700,
          iconTheme: const IconThemeData(
            size: 16,
            color: Color(0xFFFFFFFF),
          ),
        ),
        bottomAppBarTheme: BottomAppBarTheme(
          color: Colors.blueGrey.shade700,
          elevation: 8,
        ),
        backgroundColor: const Color.fromRGBO(200, 200, 200, 1),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      routes: {
        "/": (context) => const MainPage(),
        "/settings": (context) => const SettingsPage(),
      },
      initialRoute: "/",
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  // As this widget is stateful (it has a state),
  // The createState function is needed so that it can be called
  // Every time the widget (app) needs to be re-rendered.
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  int _tabIndex = 1;
  final List<String> _tabNames = [
    "Timetable",
    "Homework",
    "Dashboard",
    "Calendar",
    "Exams"
  ];

  void _tabChanged() {
    setState(() {
      _tabIndex = _tabController!.index;
    });
  }

  // This simply creates the TabController on startup.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 5, initialIndex: 2);
    _tabController!.addListener(_tabChanged);
  }

  // And this disposes of the TabController on close.
  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
        children: const [
          Timetable(),
          HomeworkPage(),
          Text("Dashboard"),
          Text("Calendar"),
          Text("Exams"),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: TabBar(
          controller: _tabController,
          unselectedLabelColor: const Color(0xFFBBBBBB),
          unselectedLabelStyle: const TextStyle(
            fontSize: 0.01,
          ),
          labelColor: const Color(0xFFFFFFFF),
          indicatorColor: Colors.purple.shade300,
          indicatorSize: TabBarIndicatorSize.label,
          enableFeedback: true,
          tabs: const <Widget>[
            Tooltip(
              message: "Timetable",
              child: Tab(
                icon: Icon(
                  Icons.calendar_today_outlined,
                  semanticLabel: "Timetable",
                ),
                child: AutoSizeText(
                  "Timetable",
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            Tooltip(
              message: "Homework",
              child: Tab(
                icon: Icon(
                  Icons.book_outlined,
                  semanticLabel: "Homework",
                ),
                child: AutoSizeText(
                  "Homework",
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            Tooltip(
              message: "Dashboard",
              child: Tab(
                icon: Icon(
                  Icons.home_outlined,
                  semanticLabel: "Dashboard",
                ),
                child: AutoSizeText(
                  "Dashboard",
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            Tooltip(
              message: "Calendar",
              child: Tab(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  semanticLabel: "Calendar",
                ),
                child: AutoSizeText(
                  "Calendar",
                  maxLines: 1,
                  minFontSize: 0,
                  maxFontSize: 16,
                ),
              ),
            ),
            Tooltip(
              message: "Exams",
              child: Tab(
                icon: Icon(
                  Icons.check_circle_outline_outlined,
                  semanticLabel: "Exams",
                ),
                child: AutoSizeText(
                  "Exams",
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
