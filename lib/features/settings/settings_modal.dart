import 'package:flutter/material.dart';
import 'package:walkyourcat/services/audio_settings.dart';

void showSettingsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          double volume = AudioSettings.sfxVolume;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.volume_up_rounded,
                                color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text("Sound Effects"),
                          ],
                        ),

                        Slider(
                          value: volume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          activeColor: Colors.deepPurple,
                          onChanged: (value) {
                            setState(() {
                              AudioSettings.setSfxVolume(value);
                              volume = value;
                            });
                          },
                        ),

                        Text(
                          volume == 0
                              ? "Muted"
                              : "Volume: ${(volume * 100).round()}%",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}