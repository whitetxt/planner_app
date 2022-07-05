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
      /*bottomNavigationBar: BottomNavigationBar(
        onTap: (int idx) => {
          setState(() {
            _page = idx;
          })
        },
        currentIndex: _page,
        elevation: 8,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.blue.shade400,
        unselectedItemColor: Colors.grey.shade500,
        enableFeedback: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: "Timetable",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: "Events",
          ),
        ],
      ),
      body: const <Widget>[
        Text("Timetable"),
        Text("Dashboard"),
        Text("Events"),
      ][_page],*/
      body: TabBarView(
        controller: _tabController,
        children: const [
          Text("Timetable"),
          Text("Dashboard"),
          Text("Events"),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          color: Colors.grey.shade500,
          child: TabBar(
            controller: _tabController,
            unselectedLabelColor: const Color(0x50FFFFFF),
            unselectedLabelStyle: const TextStyle(
              fontSize: 0,
            ),
            indicatorColor: Colors.purple.shade300,
            tabs: const <Widget>[
              Tab(
                icon: Icon(Icons.calendar_today_outlined),
                child: Text("Timetable"),
              ),
              Tab(
                icon: Icon(Icons.home_outlined),
                child: Text("Dashboard"),
              ),
              Tab(
                icon: Icon(Icons.calendar_month_outlined),
                child: Text("Events"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
