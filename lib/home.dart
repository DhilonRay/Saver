import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:neosaver/partners_orders_page.dart';
import 'package:neosaver/user_order_page.dart';
import 'aboutus.dart';
import 'userid.dart';
import 'login_screen.dart';
import 'sos_chat_page.dart';
import 'ambulance_services_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 14),
      ),
    );
  }

  Future<void> _setDestinationMarker() async {
    try {
      List<Location> locations =
          await locationFromAddress(_destinationController.text);
      if (locations.isNotEmpty) {
        _destinationPosition =
            LatLng(locations[0].latitude, locations[0].longitude);

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId('destination'),
              position: _destinationPosition!,
              infoWindow: InfoWindow(title: 'Destination'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );

          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              color: Colors.blue.shade300,
              width: 3,
              points: [
                _currentPosition!,
                _destinationPosition!,
              ],
            ),
          );
        });

        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(_destinationPosition!, 14),
        );
      }
    } catch (e) {
      print("Error finding location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not find the location")),
      );
    }
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToAmbulanceServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AmbulanceServicesPage()),
    );
  }

  void _navigateToPartnersOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PartnersOrdersPage()),
    );
  }

  void _navigateToUserOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  UserOrdersPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Live Location & Route',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey.shade800,
          elevation: 2,
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.blueGrey.shade900, 
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  child: Center(
                    child: Text(
                      'NeoSaver - Because Every seconds Matter',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                Divider(color: Colors.grey.shade700),
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.white70),
                  title: Text('User ID', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserIdPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.assignment_ind_outlined, color: Colors.white70),
                  title: Text('Your Orders (Partner)', style: TextStyle(color: Colors.white)),
                  onTap: _navigateToPartnersOrders,
                ),
                ListTile(
                  leading: Icon(Icons.assignment_outlined, color: Colors.white70),
                  title: Text('Your Orders (User)', style: TextStyle(color: Colors.white)),
                  onTap: _navigateToUserOrders,
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.white70),
                  title: Text('About Us', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUsPage()),
                    );
                  },
                ),
                Spacer(),
                Divider(color: Colors.grey.shade700),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white70),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: _signOut,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _destinationController,
                    style: TextStyle(color: Colors.blueGrey.shade800),
                    decoration: InputDecoration(
                      labelText: 'Enter destination',
                      labelStyle: TextStyle(color: Colors.blueGrey.shade600),
                      prefixIcon:
                          Icon(Icons.location_on_outlined, color: Colors.blueGrey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueGrey.shade800),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _setDestinationMarker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Set Destination',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: _currentPosition == null
                      ? Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blueGrey.shade800)))
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition!,
                            zoom: 14,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          markers: _markers,
                          polylines: _polylines,
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              bottom: 90, 
              child: ElevatedButton(
                onPressed: _navigateToAmbulanceServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.all(16),
                  shape: CircleBorder(),
                  elevation: 3,
                ),
                child: Icon(Icons.local_hospital, color: Colors.white, size: 28),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SOSChatPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: EdgeInsets.all(16),
                  shape: CircleBorder(),
                  elevation: 3,
                ),
                child: Icon(Icons.chat_bubble, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}