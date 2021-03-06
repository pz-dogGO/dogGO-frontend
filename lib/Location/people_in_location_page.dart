import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:doggo_frontend/Custom/doggo_toast.dart';
import 'package:doggo_frontend/FollowedBlocked/http/dog_lover_data.dart';
import 'package:doggo_frontend/Location/fdto/UserLiked.dart';
import 'package:doggo_frontend/Location/http/useranddogs.dart';
import 'package:doggo_frontend/OAuth2/oauth2_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';

class PeopleAndDogsInLocationPage extends StatefulWidget {
  final String markerId;
  final List<UserLiked> usersLiked;

  const PeopleAndDogsInLocationPage({Key key, this.markerId, this.usersLiked})
      : super(key: key);

  @override
  _PeopleAndDogsInLocationPageState createState() =>
      _PeopleAndDogsInLocationPageState();
}

class _PeopleAndDogsInLocationPageState
    extends State<PeopleAndDogsInLocationPage> {
  Client client;
  final headers = {'Content-Type': 'application/json', 'Accept': '*/*'};
  final authority = 'doggo-service.herokuapp.com';

  Timer timer;
  Future<List<UserAndDogsInLocation>> _usersanddogs;
  List<UserLiked> _usersLiked;

  @override
  void initState() {
    timer = new Timer.periodic(Duration(seconds: 10), (Timer timer) {
      _usersanddogs = _fetchUsersAndDogsInLocation(widget.markerId);
      _setUserLiked(_usersanddogs);
    });
    setState(() {
      _usersanddogs = _fetchUsersAndDogsInLocation(widget.markerId);
      _usersLiked = widget.usersLiked;
      _setUserLiked(_usersanddogs);
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _setUserLiked(
      Future<List<UserAndDogsInLocation>> futureUsersAndDogs) async {
    List<UserAndDogsInLocation> usersAndDogs = await futureUsersAndDogs;
    List<String> userIds = usersAndDogs.map((e) => e.userId).toList();
    if (_usersLiked.isEmpty)
      _usersLiked = usersAndDogs.map(
          (e) => UserLiked(id: e.userId, liked: false, likes: e.likesCount)).toList();
    else {
      _usersLiked.removeWhere((element) => !userIds.contains(element.id));
      for (UserAndDogsInLocation e in usersAndDogs) {
        if (!_usersLiked.contains(e.userId))
          _usersLiked
              .add(UserLiked(id: e.userId, liked: false, likes: e.likesCount));
      }
    }
  }

  Future<List<UserAndDogsInLocation>> _fetchUsersAndDogsInLocation(
      String markerId) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url =
        'https://doggo-service.herokuapp.com/api/dog-lover/walks/dog-lovers-in-location/$markerId';
    final response = await client.get(url, headers: headers);
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonResponse
          .map((useranddogs) => UserAndDogsInLocation.fromJson(useranddogs))
          .toList();
    } else {
      DoggoToast.of(context).showToast(
          'Failed to load users and dogs in given location ${response.statusCode}');
      //TODO: log error
    }
  }

  Future<bool> _likeUser(String uID) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final headers = {'Content-Type': 'application/json', 'Accept': '*/*'};
    final authority = 'doggo-service.herokuapp.com';
    final path = '/api/dog-lover/dog-lover-likes';
    final queryParameters = {'receiverDogLoverId': '$uID'};
    final url = Uri.https(authority, path, queryParameters);

    final response = await client.post(url, headers: headers);
    switch (response.statusCode) {
      case 201:
        {
          setState(() {
            _usersLiked.firstWhere((element) => element.id == uID).likes++;
            _usersLiked.firstWhere((element) => element.id == uID).liked = true;
          });
          return true;
        }
      case 400:
        {
          DoggoToast.of(context)
              .showToast('People are not currently at the same location.');
          return false;
        }
      case 404:
        {
          DoggoToast.of(context).showToast('You are not in any location.');
          return false;
        }
      case 409:
        {
          DoggoToast.of(context)
              .showToast('Person has already been liked in current walk.');
          return false;
        }
      default:
        {
          DoggoToast.of(context).showToast('Couldn\'t like person.');
          return false;
        }
    }
  }

  Future<bool> _undoUserLike(String uID) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final path = '/api/dog-lover/dog-lover-likes';
    final queryParameters = {'receiverDogLoverId': '$uID'};
    final url = Uri.https(authority, path, queryParameters);

    final response = await client.delete(url, headers: headers);
    switch (response.statusCode) {
      case 204:
        {
          setState(() {
            _usersLiked.firstWhere((element) => element.id == uID).likes--;
            _usersLiked.firstWhere((element) => element.id == uID).liked =
                false;
          });
          return true;
        }
      case 400:
        {
          DoggoToast.of(context)
              .showToast('People are not currently at the same location.');
          return false;
        }
      case 404:
        {
          DoggoToast.of(context).showToast('You are not in any location.');
          return false;
        }
      default:
        {
          DoggoToast.of(context).showToast('Couldn\'t undo person like.');
          return false;
        }
    }
  }

  Future _addFollowedBlocked(String nickname, String action) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final authority = 'doggo-service.herokuapp.com';
    final path = '/api/dog-lover/relationships/$nickname';
    final queryParameters = {'status': '${action}S'};
    final url = Uri.https(authority, path, queryParameters);

    final response = await client.post(url, headers: headers);
    switch (response.statusCode) {
      case 201:
        {
          DoggoToast.of(context)
              .showToast('Person added to ${action}ED successfully.');
          break;
        }
      case 404:
        {
          DoggoToast.of(context)
              .showToast('Person with given nickname doesn\'t exist.');
          break;
        }
      case 409:
        {
          DoggoToast.of(context).showToast(
              'This person is already in relation with you. Delete relation in Relations list.');
          break;
        }
      default:
        {
          DoggoToast.of(context)
              .showToast('Could add person to FOLLOWED or BLOCKED.');
          break;
        }
    }
  }

  Future<Uint8List> _fetchUserAvatar(String id) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url =
        'https://doggo-service.herokuapp.com/api/dog-lover/profiles/$id/avatar';

    final response = await client.get(url, headers: headers);
    switch (response.statusCode) {
      case 200:
        {
          return response.bodyBytes;
        }
      case 404:
        {
          break;
        }
      default:
        {
          DoggoToast.of(context)
              .showToast('Couldn\'t load user (id: $id) avatar.');
          break;
        }
    }
  }

  Future<Uint8List> _fetchDogAvatar(String id) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url =
        'https://doggo-service.herokuapp.com/api/dog-lover/dogs/$id/avatar';

    final response = await client.get(url, headers: headers);
    switch (response.statusCode) {
      case 200:
        {
          return response.bodyBytes;
        }
      case 404:
        {
          break;
        }
      default:
        {
          DoggoToast.of(context).showToast('Couldn\'t load dog avatar.');
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double buttonsHeight = screenHeight * 0.01;
    double buttonsWidth = screenWidth * 0.05;

    return Scaffold(
        appBar: AppBar(
            leading: BackButton(
              onPressed: () => Navigator.pop(context, _usersLiked),
            ),
            backgroundColor: Colors.orangeAccent,
            centerTitle: true,
            title: Text('People In Current Location')),
        body: FutureBuilder<List<UserAndDogsInLocation>>(
            future: _usersanddogs,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<UserAndDogsInLocation> usersanddogs = snapshot.data;
                return ListView.builder(
                    itemCount: usersanddogs.length,
                    itemBuilder: (context, userIndex) {
                      return Card(
                        elevation: 5,
                        child: ExpansionTile(
                          title: Text(
                            usersanddogs[userIndex].nickname,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                usersanddogs[userIndex].name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w300, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(_usersLiked
                                            .firstWhere((element) =>
                                                element.id ==
                                                usersanddogs[userIndex].userId)
                                            .liked
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_alt_outlined),
                                    color: Colors.orangeAccent,
                                    onPressed: () {
                                      if (!_usersLiked
                                          .firstWhere((element) =>
                                              element.id ==
                                              usersanddogs[userIndex].userId)
                                          .liked) {
                                        _likeUser(usersanddogs[userIndex].userId);
                                      } else {
                                        _undoUserLike(usersanddogs[userIndex].userId);
                                      }
                                    },
                                  ),
                                  Text(
                                    _usersLiked
                                        .firstWhere((element) =>
                                            element.id ==
                                            usersanddogs[userIndex].userId)
                                        .likes
                                        .toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          leading: FutureBuilder<Uint8List>(
                            future: _fetchUserAvatar(usersanddogs[userIndex].userId),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                Uint8List bytes = snapshot.data;
                                return CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.memory(
                                        bytes,
                                        key: ValueKey(bytes.lengthInBytes),
                                        width: screenHeight * 0.18,
                                        height: screenHeight * 0.18,
                                        fit: BoxFit.fitHeight,
                                      ),
                                    ));
                              } else {
                                return Icon(Icons.account_circle, color: Colors.orangeAccent);
                              }
                            },
                          ),
                          children: [
                            ListView.builder(
                                shrinkWrap: true,
                                itemCount: usersanddogs[userIndex].dogs.length,
                                itemBuilder: (context, dogIndex) {
                                  return Card(
                                    elevation: 5,
                                    child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.005,
                                            horizontal: screenWidth * 0.17),
                                        leading: FutureBuilder<Uint8List>(
                                          future: _fetchDogAvatar(
                                              usersanddogs[userIndex].dogs[dogIndex].id),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              Uint8List bytes = snapshot.data;
                                              return CircleAvatar(
                                                  backgroundColor: Colors.grey[200],
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(50),
                                                    child: Image.memory(
                                                      bytes,
                                                      key: ValueKey(bytes.lengthInBytes),
                                                      width: screenHeight * 0.18,
                                                      height: screenHeight * 0.18,
                                                      fit: BoxFit.fitHeight,
                                                    ),
                                                  ));
                                            } else {
                                              return Icon(Icons.pets, color: Colors.orangeAccent);
                                            }
                                          },
                                        ),
                                        title: Text(
                                            usersanddogs[userIndex].dogs[dogIndex].name),
                                        subtitle: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(usersanddogs[userIndex]
                                                .dogs[dogIndex]
                                                .breed),
                                            Text(usersanddogs[userIndex]
                                                .dogs[dogIndex]
                                                .color)
                                          ],
                                        )),
                                  );
                                }),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FlatButton.icon(
                                    icon: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7.0)),
                                    color: Colors.orange,
                                    disabledColor: Colors.white30,
                                    textColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        vertical: buttonsHeight,
                                        horizontal: buttonsWidth),
                                    label: Text('Follow'),
                                    onPressed: () {
                                      if (usersanddogs[userIndex].relationStatus ==
                                          RelationStatus.FOLLOWED)
                                        return null;
                                      else {
                                        _addFollowedBlocked(
                                            usersanddogs[userIndex].nickname,
                                            'FOLLOW');
                                        setState(() {
                                          usersanddogs[userIndex].relationStatus =
                                              RelationStatus.FOLLOWED;
                                        });
                                      }
                                    }),
                                FlatButton.icon(
                                    icon: Icon(
                                      Icons.block,
                                      color: Colors.white,
                                    ),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7.0)),
                                    color: Colors.orange[900],
                                    disabledColor: Colors.white30,
                                    textColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        vertical: buttonsHeight,
                                        horizontal: buttonsWidth),
                                    label: Text('Block'),
                                    onPressed: () {
                                      _addFollowedBlocked(
                                          usersanddogs[userIndex].nickname, 'BLOCK');
                                      setState(() {
                                        usersanddogs[userIndex].relationStatus =
                                            RelationStatus.BLOCKED;
                                      });
                                    }),
                              ],
                            ),
                          ],
                        ),
                      );
                    });
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }));
  }
}
