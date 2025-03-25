import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BusTrackingScreen(),
    );
  }
}

class BusTrackingScreen extends StatefulWidget {
  @override
  _BusTrackingScreenState createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  late IO.Socket socket;
  LatLng? currentPosition;
  List<LatLng> buses = [];

  @override
  void initState() {
    super.initState();
    conectarSocket();
    obtenerUbicacion();
  }

  void conectarSocket() {
    socket = IO.io(
      'https://v6j2m2c7-3000.brs.devtunnels.ms',
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.on('connect', (_) => print('Conectado al servidor'));

    socket.on('actualizar_buses', (data) {
      setState(() {
        buses.add(LatLng(data['coordenadas'][0], data['coordenadas'][1]));
      });
    });
  }

  void obtenerUbicacion() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    Position posicion = await Geolocator.getCurrentPosition();
    setState(
      () => currentPosition = LatLng(posicion.latitude, posicion.longitude),
    );

    socket.emit('ubicacion_pasajero', {
      'coordenadas': [posicion.latitude, posicion.longitude],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: currentPosition ?? LatLng(-12.0464, -77.0428),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers:
                buses
                    .map(
                      (bus) => Marker(
                        point: bus,
                        width: 30, // Tamaño del marcador
                        height: 30,
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
