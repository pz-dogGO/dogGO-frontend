import 'dart:convert';

import 'package:doggo_frontend/Custom/doggo_toast.dart';
import 'package:doggo_frontend/Dog/edit_dog_data_page.dart';
import 'package:doggo_frontend/Dog/http/dog_data.dart';
import 'package:doggo_frontend/Dog/set_dog_data_page.dart';
import 'package:doggo_frontend/OAuth2/oauth2_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oauth2/oauth2.dart';

class _DogsListPageState extends State<DogsListPage> {
  Client client;
  final url = 'https://doggo-service.herokuapp.com/api/dog-lover/dogs';
  final headers = {'Content-Type': 'application/json', 'Accept': '*/*'};

  Future<List<Dog>> _dogs;

  @override
  void initState() {
    setState(() {
      _dogs = _fetchDogs();
    });
    super.initState();
  }

  Future<List<Dog>> _fetchDogs() async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);

    final response = await client.get(url, headers: headers);
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((dog) => Dog.fromJson(dog)).toList();
    } else {
      DoggoToast.of(context).showToast('Failed to load dogs.');
      throw Exception('Failed to load dogs from API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your dogs'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn1",
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => SetDogDataPage(),
                ),
              )
              .whenComplete(() => {
                    setState(() {
                      _dogs = _fetchDogs();
                    })
                  });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
        splashColor: Colors.orange,
      ),
      body: FutureBuilder<List<Dog>>(
        future: _dogs,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Dog> dogs = snapshot.data;
            return ListView.builder(
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(
                      dogs[index].name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Breed: ${dogs[index].breed}"),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Color: ${dogs[index].color}"),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child:
                              Text("Description: ${dogs[index].description}"),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "Last vaccination date: ${DateFormat("dd-MM-yyy").format(dogs[index].vaccinationDate)}"),
                        )
                      ],
                    ),
                    leading: Icon(
                      Icons.pets,
                      color: Colors.orangeAccent,
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (context) => EditDogDataPage(
                                dogData: dogs[index],
                              ),
                            ))
                            .whenComplete(() => {
                                  setState(() {
                                    _dogs = _fetchDogs();
                                  })
                                });
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                  elevation: 5,
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.orangeAccent,
            ),
          );
        },
      ),
    );
  }
}

class DogsListPage extends StatefulWidget {
  @override
  _DogsListPageState createState() => _DogsListPageState();
}
