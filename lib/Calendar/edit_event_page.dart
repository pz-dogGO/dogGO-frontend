import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:doggo_frontend/Custom/doggo_toast.dart';
import 'package:doggo_frontend/Custom/extensions.dart';
import 'package:doggo_frontend/Dog/http/dog_data.dart';
import 'package:doggo_frontend/OAuth2/oauth2_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oauth2/oauth2.dart';

import 'http/event_data.dart';

class _EditEventPageState extends State<EditEventPage> {
  Client client;
  var headers = {'Content-Type': 'application/json', 'Accept': '*/*'};

  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedDog;
  List<dynamic> _dogs = List();

  @override
  void initState() {
    if (widget.eventData != null) {
      dateController.text =
          DateFormat('yyyy-MM-dd').format(widget.eventData.eventDateTime);
      timeController.text = TimeOfDay.fromDateTime(widget.eventData.eventDateTime).toString();
      descriptionController.text = widget.eventData.description;
      selectedDog = widget.eventData.dogName;
    }
    _fetchDogs();
    super.initState();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _fetchDogs() async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url = 'https://doggo-service.herokuapp.com/api/dog-lover/dogs';

    final response = await client.get(url, headers: headers);
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var temp = jsonResponse.map((dog) => Dog.fromJson(dog)).toList();
      setState(() {
        _dogs = temp;
      });
    } else {
      DoggoToast.of(context).showToast('Failed to load dogs details.');
      throw Exception('Failed to load dogs from API');
    }
  }

  Future editEventData() async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    var url =
        'https://doggo-service.herokuapp.com/api/dog-lover/user-calendar-events';
    var body = jsonEncode({
      'id': '${widget.eventData.eventId}',
      'date': '${dateController.text}',
      'time': '${timeController.text}',
      'description': '${descriptionController.text}',
      'dogName': '$selectedDog'
    });

    final response = await client.put(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      Navigator.of(context).pop();
    } else {
      DoggoToast.of(context).showToast('Could not edit calendar event!');
      throw Exception('Could not edit calendar event');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Edit Event In Your Calendar'),
          centerTitle: true,
          backgroundColor: Colors.orangeAccent),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: 10),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.orangeAccent,
                                blurRadius: 20,
                                offset: Offset(0, 10))
                          ]),
                      child: Column(
                        children: <Widget>[
                          Text('Click below to select event date',
                              style: TextStyle(color: Colors.grey)),
                          DateTimeField(
                            controller: dateController,
                            format: DateFormat("yyyy-MM-dd"),
                            onShowPicker: (context, currentValue) {
                              return showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  initialDate: currentValue ?? DateTime.now(),
                                  lastDate: DateTime(2025));
                            },
                          ),
                          Divider(color: Colors.grey),
                          Text('Click below to select event time',
                              style: TextStyle(color: Colors.grey)),
                          DateTimeField(
                            controller: timeController,
                            format: DateFormat("HH:mm"),
                            onShowPicker: (context, currentValue) async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                    currentValue ?? DateTime.now()),
                              );
                              return DateTimeField.convert(time);
                            },
                          ),
                          Divider(color: Colors.grey),
                          Container(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Description",
                                  hintStyle: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          Divider(color: Colors.grey),
                          DropdownButtonHideUnderline(
                            child: DropdownButton(
                              isExpanded: true,
                              hint: Text("Select your dog"),
                              value: selectedDog,
                              items: _dogs.map((doggo) {
                                return DropdownMenuItem(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 7),
                                    child: Text(doggo.name),
                                  ),
                                  value: doggo.name,
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDog = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      height: 50.0,
                      child: MaterialButton(
                        onPressed: () {
                          if (dateController.text == "") {
                            DoggoToast.of(context)
                                .showToast('Date and time has to be filled!');
                            throw Exception('Date and time are empty');
                          } else {
                            editEventData();
                          }
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.all(0.0),
                        child: Ink(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orangeAccent,
                                  Color.fromRGBO(200, 100, 20, .4)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10)),
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth: 300.0, minHeight: 50.0),
                            alignment: Alignment.center,
                            child: Text(
                              "Edit Event",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditEventPage extends StatefulWidget {
  final Event eventData;

  const EditEventPage({Key key, this.eventData}) : super(key: key);

  @override
  _EditEventPageState createState() => _EditEventPageState();
}
