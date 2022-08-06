import "package:flutter/material.dart";

import "pl_appbar.dart";

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PLAppBar("Dashboard", context),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Text("Hoi"),
      ),
    );
  }
}
