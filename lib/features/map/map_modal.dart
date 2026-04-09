import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void showMapModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const MapModalContent(),
      );
    },
  );
}

class MapModalContent extends StatelessWidget {
  const MapModalContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "Map",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        const Expanded(child: MapModalService()),
      ],
    );
  }
}

class MapModalService extends StatefulWidget {
  const MapModalService({super.key});

  @override
  State<MapModalService> createState() => _MapModalServiceState();
}

class _MapModalServiceState extends State<MapModalService> {
  @override
  Widget build(BuildContext context) {
    
  }
}