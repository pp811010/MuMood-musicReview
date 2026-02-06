
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:frontend/screens/Home.dart';


class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _PostListPageState();
}

class _PostListPageState extends State<App> {
  int myindex = 0;

  List<Widget> widgetList = [Home()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: myindex, children: widgetList),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[800]!.withOpacity(0.9),
        onTap: (index) {
          setState(() {
            myindex = index;
          });
        },
        selectedItemColor: const Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        currentIndex: myindex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home" ),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favorite"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account")
        ],
      ),
    );
  }
}
