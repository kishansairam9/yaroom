import 'package:flutter/material.dart';
import 'pullLeft.dart';

class RoomsList extends StatelessWidget {
  late final bool animateInsteadOfNavigateHome;

  RoomsList({required this.animateInsteadOfNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: IconButton(
              icon: Icon(Icons.home),
              onPressed: () => animateInsteadOfNavigateHome
                  ? PullLeftWrapper.of(context)?.close()
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
  @override
  RoomsState createState() => RoomsState();
}

class RoomsState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return PullLeftWrapper(
        keepOpenAtStart: true,
        leftContent: RoomsList(
          animateInsteadOfNavigateHome: false,
        ),
        mainContent: PullLeftWrapper(
          maxSlide: 500,
          minDragStartEdge: 800,
          leftContent: Container(
            color: Colors.amber,
          ),
          mainContent: Container(
            color: Colors.red,
          ),
        ));
  }
}
