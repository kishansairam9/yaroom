import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/authorizationService.dart';
import 'package:provider/provider.dart';

class ExchangeSearchDelegate extends SearchDelegate {
  late final String exchangeId;
  late final String msgType;
  late final int limit;

  ExchangeSearchDelegate(
      {required this.exchangeId, required this.msgType, required this.limit})
      : super();

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
          onPressed: () => {close(context, null)},
          icon: Icon(Icons.close),
          tooltip: 'Cancel')
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () => {close(context, null)},
        icon: Icon(Icons.arrow_back),
        tooltip: 'Cancel');
  }

  Future<Widget> search(BuildContext context) async {
    if (query.isEmpty) {
      return Center(
        child: Text("Enter query"),
      );
    }

    final String? accessToken =
        await Provider.of<AuthorizationService>(context, listen: false)
            .getValidAccessToken();
    var req = await http.get(
        Uri.parse(
            'http://localhost:8884/v1/search?exchangeId=$exchangeId&msgType=$msgType&limit=$limit&searchString=${query.toLowerCase()}'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print(req.body);
    if (req.body == "null") {
      return Center(
        child: Text("No matches"),
      );
    }
    if (req.body.contains(new RegExp("{\"error\"", caseSensitive: false))) {
      return Center(
        child: Text("Server error, report to support"),
      );
    }
    var results = jsonDecode(req.body).cast<Map<String, dynamic>>();
    return ListView(
        children: results.map<Widget>((Map e) {
      DateTime time = DateTime.parse(e['time']).toLocal();
      String timeStamp =
          "${time.day.toString().padLeft(2, "0")}/${time.month.toString().padLeft(2, "0")}/${time.year.toString().substring(2)} ${TimeOfDay.fromDateTime(time.toLocal()).format(context)};";
      return Card(
          child: ResultTile(
              msgId: e['msgId'], time: timeStamp, text: e['content']));
    }).toList());
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
        future: search(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
        future: search(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }
}

class ResultTile extends StatefulWidget {
  late final String time;
  late final String text;
  late final String msgId;

  ResultTile({required this.time, required this.text, required this.msgId});

  @override
  ResultTileState createState() => ResultTileState();
}

class ResultTileState extends State<ResultTile> {
  ResultTileState();

  @override
  Widget build(BuildContext context) {
    // return Card(
    return ListTile(
      minVerticalPadding: 25.0,
      title: Text(widget.text),
      subtitle: Text(widget.time),
    );
    // );
  }
}
