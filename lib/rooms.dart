import 'package:flutter/material.dart';
import 'inner_drawer.dart';
import 'tabs.dart';

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

class Rooms extends StatefulWidget {
  static TabViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<TabViewState>();

  @override
  RoomsState createState() => RoomsState();
}

class RoomsState extends State<StatefulWidget> {
  //  Current State of InnerDrawerState
  final GlobalKey<InnerDrawerState> _innerDrawerKey =
      GlobalKey<InnerDrawerState>();

  void toggle() {
    _innerDrawerKey.currentState!.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return InnerDrawer(
      scaffold: Container(color: Colors.red),
      leftChild: RoomsList(
        animateInsteadOfNavigateHome: false,
      ),
      rightChild: Container(color: Colors.lime),
    );
  }
}
