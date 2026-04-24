import 'package:flutter/material.dart';

void showSettingsModal(BuildContext context) {
  double volume = 0.7; // you can later connect this to AudioPlayer

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                  // handle bar
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
                      color: Color(0xFF2F1F17),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SOUND SECTION CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.volume_up_rounded,
                                color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              "Sound",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F1F17),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // volume slider
                        Slider(
                          value: volume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          activeColor: Colors.deepPurple,
                          onChanged: (value) {
                            setState(() {
                              volume = value;
                            });
                            // hook into audio later if needed
                            // player.setVolume(volume);
                          },
                        ),

                        // quick toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Mute",
                              style: TextStyle(
                                color: Color(0xFF2F1F17),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: volume > 0,
                              activeColor: Colors.deepPurple,
                              onChanged: (val) {
                                setState(() {
                                  volume = val ? 0.7 : 0.0;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

class SettingsModalContent extends StatefulWidget {
  const SettingsModalContent({super.key});

  @override
  State<SettingsModalContent> createState() => _SettingsModalContentState();
}

class _SettingsModalContentState extends State<SettingsModalContent> {
  bool _soundEnabled = true;
  double _volume = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Sound toggle
          SwitchListTile(
            title: const Text("Sound Effects"),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
                
                if (!value) {
                  _volume = 0.0;
                } else if (_volume == 0.0) {
                  _volume = 0.5;
                }
              });
            },
          ),

          // Volume Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Volume"),
              Slider(
                value: _volume,
                onChanged: _soundEnabled
                    ? (value) {
                        setState(() {
                          _volume = value;
                        });
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
