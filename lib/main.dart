import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import "timetable.dart";

void main() {
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
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
  }

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
        children: const [
          Timetable(),
          Text("Dashboard"),
          Text("Events"),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Container(
          color: Colors.grey.shade400,
          child: TabBar(
            controller: _tabController,
            unselectedLabelColor: const Color.fromARGB(75, 0, 0, 0),
            unselectedLabelStyle: const TextStyle(
              fontSize: 0,
            ),
            labelColor: const Color.fromARGB(255, 0, 0, 0),
            indicatorColor: Colors.purple.shade300,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const <Widget>[
              Tooltip(
                message: "Timetable",
                child: Tab(
                  icon: Icon(Icons.calendar_today_outlined),
                  child: Text("Timetable"),
                ),
              ),
              Tooltip(
                message: "Dashboard",
                child: Tab(
                  icon: Icon(Icons.home_outlined),
                  child: Text("Dashboard"),
                ),
              ),
              Tooltip(
                message: "Events ",
                child: Tab(
                  icon: Icon(Icons.calendar_month_outlined),
                  child: Text("Events"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
