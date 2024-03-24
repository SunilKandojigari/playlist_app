import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class DeviceInfoWidget extends StatefulWidget {
  @override
  _DeviceInfoWidgetState createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget> {
  String? _deviceId = ''; // variable to store device ID
  String? _key = ''; //  variable to store the key value generated from api
  List<String> fileUrls = []; // list to store urls of file values in response from the api
  int currentIndex = 0;  // variable to itarate the fileurl list

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }
//creating _getDeviceId method to get the deviceId
  Future<void> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceId = androidInfo.androidId; // Use androidId as device ID
      });
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceId =
            iosInfo.identifierForVendor; // Use identifierForVendor as device ID
      });
    }
    fetchData(); // Call fetchData after getting device ID
  }

  Future<void> fetchData() async {
    // Define the API endpoint
    String apiUrl =
        'https://stagegallery.rinx.com/mobileapp/fetch_playlist_task/';
    //String apiUrl = 'https://stagegallery.rinx.com/mobileapp/generate_key_task/';

    // Encode the device ID to JSON
    Map<String, dynamic> requestBody = {'device_id': _deviceId};

    // Convert the JSON parameters to a query strin
    // Append the query string to the API URL

    try {
      // Make the API request
      final response = await http.post(
        Uri.parse('https://stagegallery.rinx.com/mobileapp/generate_key_task/'),
        headers: {
          'Content-Type': 'application/json', // Set the content type
        },
        body: jsonEncode(requestBody), // Encode the request body to JSON
      );

      if (response.statusCode == 200) {
        // API call successful, handle response data
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String key = responseBody['key'];
        setState(() {
          _key = key; // Update the state variable
        });
        print(response.body);
        print('Key: $_key');
        // Make the API request to fetch data with key as path parameter
        final playlistResponse = await http.get(
          Uri.parse('$apiUrl$_key/'),
        );

        if (playlistResponse.statusCode == 200) {
          // API call successful, handle response data
          Map<String, dynamic> playlistData = jsonDecode(playlistResponse.body);
          setState(() {
            List<dynamic> mediaIds = playlistData['media_ids'];

// Iterate over each element in the media_ids list
            for (var media in mediaIds) {
              // Check if the current media element contains the 'file' key
              if (media.containsKey('file')) {
                // Extract the 'file' value and add it to the list of file URLs
                fileUrls.add(media['file']);
              }
            }
          });
          _navigateToSecondPage(currentIndex);
          Timer.periodic(Duration(minutes: 1), (Timer timer) {
            // Call the _navigateToSecondPage method
            currentIndex = (currentIndex + 1) % fileUrls.length;
            _navigateToSecondPage(currentIndex);
          });

//
        } else {
          // API call failed, handle error
          print(
              'Failed to fetch playlist data: ${playlistResponse.statusCode}');
        }
      } else {
        // API call failed, handle error
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occur during the API request
      print('Error fetching data: $error');
    }
  }

  void _navigateToSecondPage(int i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(gen_key: _key, fileUrl: fileUrls[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' Demo App',
            style: TextStyle(
                fontSize: 25, // Set the font size here
                color: Colors.deepPurple)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              textAlign: TextAlign.center,
              'Pair code: $_key', // Display the key value
              style: TextStyle(fontSize: 50),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  final String? gen_key;
  final String? fileUrl;

  const SecondPage({Key? key, this.gen_key, this.fileUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            // Display the WebView
            WebView(
              initialUrl: fileUrl!,
              javascriptMode: JavascriptMode.unrestricted,
              onPageFinished: (String url) {
                // Handle WebView finished loading event
                // Here you can hide the loading indicator if needed
              },
            ),
            // Loading indicator
            Positioned.fill(
              child: fileUrl == null
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
