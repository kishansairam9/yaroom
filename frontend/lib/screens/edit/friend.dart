import 'package:flutter/material.dart';
import '../../utils/backendRequests.dart';
import '../../utils/types.dart';
import '../../moor/db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddFriend extends StatefulWidget {
  const AddFriend({Key? key}) : super(key: key);

  @override
  AddFriendState createState() {
    return AddFriendState();
  }
}

class AddFriendState extends State<AddFriend> {
  final _formKey = GlobalKey<FormState>();

  final myController = TextEditingController();

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

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
              controller: myController,
              decoration: const InputDecoration(
                icon: Icon(Icons.person_add),
                labelText: 'Enter Username',
                
              ),
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
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    String uid = myController.text;
                    await friendRequest(
                        uid, FriendRequestType.pending.index, context);
                    await RepositoryProvider.of<AppDb>(context)
                        .updateFriendRequest(status: 5, userId: uid);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sent Request')),
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
