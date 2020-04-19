import 'dart:convert';

import 'package:doggo_frontend/Dog/edit_dog_data_page.dart';
import 'package:doggo_frontend/Dog/http/dog_data.dart';
import 'package:doggo_frontend/Dog/set_dog_data_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DogsListPage extends StatefulWidget {
  @override
  _DogsListPageState createState() => _DogsListPageState();
}

class _DogsListPageState extends State<DogsListPage> {
  Future<List<Dog>> _dogs;

  @override
  void initState() {
    super.initState();
    setState(() {
      _dogs = _fetchDogs();
    });
  }

  Future<List<Dog>> _fetchDogs() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final url = 'https://doggo-app-server.herokuapp.com/api/dogs';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Authorization': 'Bearer $token'
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((dog) => Dog.fromJson(dog)).toList();
    } else {
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
                              builder: (context) => EditDogDataPage(),
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
