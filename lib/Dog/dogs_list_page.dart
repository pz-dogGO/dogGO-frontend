import 'dart:convert';
import 'dart:io';
import 'package:doggo_frontend/Custom/doggo_toast.dart';
import 'package:doggo_frontend/Dog/edit_dog_data_page.dart';
import 'package:doggo_frontend/Dog/http/dog_data.dart';
import 'package:doggo_frontend/Dog/set_dog_data_page.dart';
import 'package:doggo_frontend/OAuth2/oauth2_client.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oauth2/oauth2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class _DogsListPageState extends State<DogsListPage> {
  Client client;
  final url = 'https://doggo-service.herokuapp.com/api/dog-lover/dogs';
  final headers = {'Content-Type': 'application/json', 'Accept': '*/*'};
  Directory _dogAvatarsDirectory;

  Future<List<Dog>> _dogs;

  File _image;
  final picker = ImagePicker();

  @override
  void initState() {
    _initDocumentsDirectory();
    setState(() {
      _dogs = _fetchDogs();
    });
    super.initState();
  }

  void _initDocumentsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    _dogAvatarsDirectory = Directory('${documentsDirectory.path}/dog_avatars');
    if (!_dogAvatarsDirectory.existsSync()) {
      _dogAvatarsDirectory = await _dogAvatarsDirectory.create(recursive: true);
    }
  }

  Future<List<Dog>> _fetchDogs() async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);

    final response = await client.get(url, headers: headers);
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((dog) => Dog.fromJson(dog)).toList();
    } else {
      DoggoToast.of(context).showToast('Failed to load dogs.');
      throw Exception('Failed to load dogs from API');
    }
  }

  Future _removeDog(String id) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url = 'https://doggo-service.herokuapp.com/api/dog-lover/dogs/$id';

    final response = await client.delete(url, headers: headers);
    switch (response.statusCode) {
      case 204:
        {
          setState(() {
            _dogs = _fetchDogs();
          });
          break;
        }
      case 404:
        {
          DoggoToast.of(context).showToast('Dog doesn\'t exist.');
          break;
        }
      default:
        {
          DoggoToast.of(context).showToast('Couldn\'t remove dog.');
          break;
        }
    }
  }

  void _sendAvatar(String id) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url =
        'https://doggo-service.herokuapp.com/api/dog-lover/dogs/$id/avatar';
    final uri = Uri.parse(url);

    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath(
          'avatar', '${_dogAvatarsDirectory.path}/$id.jpg'));

    final response = await client.send(request);
    switch (response.statusCode) {
      case 200:
        {
          break;
        }
      case 400:
        {
          DoggoToast.of(context)
              .showToast('Avatar image is not a correct image.');
          break;
        }
      case 404:
        {
          DoggoToast.of(context).showToast('Dog not found.');
          break;
        }
      default:
        {
          DoggoToast.of(context).showToast('Couldn\'t send dog avatar.');
          break;
        }
    }
  }

  void _fetchAvatar(String id) async {
    client ??= await OAuth2Client().loadCredentialsFromFile(context);
    final url =
        'https://doggo-service.herokuapp.com/api/dog-lover/dogs/$id/avatar';

    final response = await client.get(url, headers: headers);
    switch (response.statusCode) {
      case 200:
        {
          File('${_dogAvatarsDirectory.path}/$id.jpg')
              .writeAsBytesSync(response.bodyBytes);
          setState(() {
            imageCache.clear();
            imageCache.clearLiveImages();
            _image = File('${_dogAvatarsDirectory.path}/$id.jpg');
          });
          break;
        }
      case 404:
        {
          DoggoToast.of(context).showToast('Dog or dog\'s avatar not found.');
          break;
        }
      default:
        {
          DoggoToast.of(context).showToast('Couldn\'t load dog avatar.');
          break;
        }
    }
  }

  void _saveAvatar(String id) async {
    File newImage = await _image.copy('${_dogAvatarsDirectory.path}/$id.jpg');
    setState(() {
      imageCache.clear();
      imageCache.clearLiveImages();
      // _image = newImage;
    });
    _sendAvatar(id);
  }

  void _setAvatar(String id, String avatarChecksum) {
    if (avatarChecksum != null) {
      _image = File('${_dogAvatarsDirectory.path}/$id.jpg');
      if (!_image.existsSync()) {
        _fetchAvatar(id);
      }
    }
  }

  void _removeDogAvatar(String id) {
    File file = File('${_dogAvatarsDirectory.path}/$id.jpg');
    if (file.existsSync()) {
      file.delete();
    }
  }

  Future _getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        imageCache.clear();
        imageCache.clearLiveImages();
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future _getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        imageCache.clear();
        imageCache.clearLiveImages();
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<Null> _cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
        maxWidth: 500,
        maxHeight: 500,
        cropStyle: CropStyle.circle,
        sourcePath: _image.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      setState(() {
        _image = croppedFile;
      });
    }
  }

  void _showPicker(context, String id) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Photo Library'),
                      onTap: () {
                        _getImageFromGallery().whenComplete(() =>
                            _cropImage().whenComplete(() => _saveAvatar(id)));
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Camera'),
                    onTap: () {
                      _getImageFromCamera().whenComplete(() =>
                          _cropImage().whenComplete(() => _saveAvatar(id)));
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Dogs'),
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
            dogs.sort((a, b) => a.name.compareTo(b.name));
            dogs.forEach(
                (element) => _setAvatar(element.id, element.avatarChecksum));
            return ListView.builder(
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  background: Stack(
                    children: [
                      Container(color: Colors.redAccent),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: screenWidth * 0.05),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  direction: DismissDirection.endToStart,
                  key: ValueKey(dogs[index]),
                  confirmDismiss: (direction) async {
                    if (dogs.length > 1) {
                      return true;
                    }
                    DoggoToast.of(context)
                        .showToast('You can\'t remove Your only dog.');
                    return false;
                  },
                  onDismissed: (direction) {
                    _removeDog(dogs[index].id);
                    _removeDogAvatar(dogs[index].id);
                    dogs.removeAt(index);
                  },
                  child: Card(
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          child: GestureDetector(
                            onTap: () {
                              _showPicker(context, dogs[index].id);
                            },
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.grey[200],
                              child:
                                  File('${_dogAvatarsDirectory.path}/${dogs[index].id}.jpg')
                                          .existsSync()
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Image.file(
                                            File(
                                                '${_dogAvatarsDirectory.path}/${dogs[index].id}.jpg'),
                                            key: ValueKey(File(
                                                    '${_dogAvatarsDirectory.path}/${dogs[index].id}.jpg')
                                                .lengthSync()),
                                            width: screenHeight * 0.13,
                                            height: screenHeight * 0.13,
                                            fit: BoxFit.fitHeight,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          width: screenHeight * 0.13,
                                          height: screenHeight * 0.13,
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                            ),
                          ),
                        ),
                        Flexible(
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
                                  child: Text(
                                      "Last vaccination date: ${DateFormat("dd-MM-yyy").format(dogs[index].vaccinationDate)}"),
                                )
                              ],
                            ),
                          ),
                        ),
                        IconButton(
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
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    elevation: 5,
                  ),
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
