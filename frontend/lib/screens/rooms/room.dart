import 'package:flutter/material.dart';
import '../../utils/inner_drawer.dart';
import '../home/tabs.dart';
import '../components/roomsList.dart';

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
