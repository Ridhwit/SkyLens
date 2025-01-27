import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sky_lens/additional_info_item.dart';
import 'package:intl/intl.dart';
import 'hourly_forecast_item.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String? _cityName; // To store the user-entered city name
  final _cityController = TextEditingController(); // TextField controller

  // Method to fetch weather details for the entered city
  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$city&APPID=a14cb1100bb568b8fe77ea84341ce9c5'),
      );
      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'An error occurred. Please check the city name.';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  // Method to prompt the user to enter the city
  Future<void> _promptForCity() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog without input
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter City"),
          content: TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: "Enter city name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_cityController.text.isNotEmpty) {
                  setState(() {
                    _cityName = _cityController.text; // Store the city name
                  });
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Prompt the user for the city on app start
    Future.delayed(Duration.zero, _promptForCity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sky Lens',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _cityName == null
          ? const Center(child: Text("Enter a city to get started"))
          : FutureBuilder(
              future: getCurrentWeather(_cityName!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                final data = snapshot.data!;
                final currentWeatherData = data['list'][0];
                final currentTemp = currentWeatherData['main']['temp'];
                final currentSky = currentWeatherData['weather'][0]['main'];
                final currentPressure = currentWeatherData['main']['pressure'];
                final currentWindSpeed = currentWeatherData['wind']['speed'];
                final currentHumidity = currentWeatherData['main']['humidity'];

                // Convert current temperature to Celsius and round it to integer
                final currentTempCelsius = (currentTemp - 273.15).toInt();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main card
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.redAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    '$currentTempCelsius°C',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    currentSky == 'Clouds' ||
                                            currentSky == 'Rain'
                                        ? Icons.cloud
                                        : Icons.wb_sunny,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    currentSky,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Weather Forecast title
                      const Text(
                        'Weather Forecast',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          itemCount: 5,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final hourlyForecast = data['list'][index + 1];
                            final hourlySky =
                                hourlyForecast['weather'][0]['main'];
                            // Convert hourly temperature from Kelvin to Celsius and round it to integer
                            final hourlyTemp =
                                (hourlyForecast['main']['temp'] - 273.15)
                                    .toInt();
                            final time =
                                DateTime.parse(hourlyForecast['dt_txt']);
                            return HourlyForecastItem(
                              time: DateFormat.j().format(time),
                              temperature: '$hourlyTemp°C',
                              icon: hourlySky == 'Clouds' || hourlySky == 'Rain'
                                  ? Icons.cloud
                                  : Icons.wb_sunny,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AdditionalInfoItem(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value: currentHumidity.toString(),
                            iconColor: Colors.blue,
                          ),
                          AdditionalInfoItem(
                            icon: Icons.air,
                            label: 'Wind Speed',
                            value: currentWindSpeed.toString(),
                            iconColor: Colors.green,
                          ),
                          AdditionalInfoItem(
                            icon: Icons.beach_access,
                            label: 'Pressure',
                            value: currentPressure.toString(),
                            iconColor: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
