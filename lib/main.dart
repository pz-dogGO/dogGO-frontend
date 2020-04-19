import 'package:doggo_frontend/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Dog/dogs_list_page.dart';
import 'Dog/edit_dog_data_page.dart';
import 'Dog/set_dog_data_page.dart';
import 'User/edit_user_profile_page.dart';
import 'User/set_user_data_page.dart';
import 'User/user_profile.dart';
import 'login_page.dart';
import 'Navigation/map_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dogGO!',
      theme: ThemeData(
          appBarTheme: AppBarTheme(color: Colors.orangeAccent),
          brightness: Brightness.light),
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/userprofile': (context) => UserProfileView(),
        '/dogsinfo': (context) => DogsListPage(),
        '/adduserdata': (context) => SetUserDataPage(),
        '/adddogdata': (context) => SetDogDataPage(),
        '/edituserdata': (context) => EditUserData(),
        '/editdogdata': (context) => EditDogData(),
        '/map': (context) => MapPage()
      },
    );
  }
}
