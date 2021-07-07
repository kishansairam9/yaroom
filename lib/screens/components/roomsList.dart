import 'package:flutter/material.dart';
import '../home/tabs.dart';

class RoomsList extends StatelessWidget {
  late final bool animateInsteadOfNavigateHome;

  RoomsList({required this.animateInsteadOfNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: IconButton(
              icon: Icon(Icons.home),
              onPressed: () => animateInsteadOfNavigateHome
                  ? TabView.of(context)?.toggle()
                  : Navigator.of(context).pushReplacementNamed('/')),
        ),
        body: Container(
          color: Colors.blue,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/rooms'),
          ),
        ));
  }
}
