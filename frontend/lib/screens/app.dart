import 'package:flutter/material.dart';
import 'user/home.dart'; // 1. หน้า Home
import 'user/favourites_page.dart'; // 2. หน้า Favorite
import 'user/history_page.dart'; // 3. หน้า History
import 'user/user_profile_page.dart'; // 4. หน้า Account/Profile

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int myindex = 0;

  List<Widget> widgetList = [
    const Home(),
    const FavoritePage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: IndexedStack(index: myindex, children: widgetList),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: myindex,
        onTap: (index) {
          setState(() {
            myindex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}
