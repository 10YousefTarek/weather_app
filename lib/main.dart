import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? tcity;

  Future getLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        tcity = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("You must Allow Permission to know your city weather")));
      } else {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          tcity = placemarks[0].administrativeArea;
        });
      }
    } else {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        tcity = placemarks[0].administrativeArea;
      });
    }
  }

  late Map weatherList;
  var img = "assets/images/sun.jpeg";
  String? countryV = "";
  double? temp = 00.0;
  String? cityV = "";
  Future weather() async {
    countryV = '';
    await getLocation();
    http.Response response = await http.get(Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=3ddf22eb7fd449fcb23111518211207&q=${tcity ?? "Ramallah"}&aqi=yes'));
    if (response.statusCode == 200) {
      String data = response.body;
      var dataDecoded = jsonDecode(data);
      var tempC = dataDecoded["current"]["temp_c"];
      var isDay = dataDecoded["current"]["is_day"];
      var country = dataDecoded["location"]["country"];
      var city = dataDecoded["location"]["name"];

      setState(() {
        weatherList = {"tempC": tempC, "country": country, "city": city};
        img = isDay == 1 ? "assets/images/sun.jpeg" : "assets/images/night.jpg";
        temp = weatherList["tempC"];
        countryV = weatherList["country"];
        cityV = weatherList["city"];
      });
    } else {
      countryV = "Error";
    }
  }

  @override
  void initState() {
    super.initState();
    weather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: countryV == ""
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black))
            : Container(
                padding: const EdgeInsets.fromLTRB(10, 70, 10, 70),
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(img), fit: BoxFit.cover)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    child: Text(
                      "$countryV,\n$cityV",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.w200),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 70),
                    child: Text(" ${temp!.toInt()}°",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 70,
                            fontWeight: FontWeight.w200),
                        textAlign: TextAlign.center),
                  ),
                ]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: weather,
        backgroundColor: Colors.black,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
