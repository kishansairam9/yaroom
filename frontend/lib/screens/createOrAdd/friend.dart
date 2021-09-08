import 'package:flutter/material.dart';

class AddFriend extends StatefulWidget {
  const AddFriend({Key? key}) : super(key: key);

  @override
  AddFriendState createState() {
    return AddFriendState();
  }
}

class AddFriendState extends State<AddFriend> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Add your Friends!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6!),
            TextFormField(
              decoration: const InputDecoration(
                  icon: Icon(Icons.person_add), labelText: 'Enter Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );
                  }
                },
                child: const Text('Send Friend Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
