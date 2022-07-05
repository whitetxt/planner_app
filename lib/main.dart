import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _page = 0;

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
          Text("Timetable"),
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
                message: "Events",
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
