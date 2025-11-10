import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundOn = true;
  bool _tiltControls = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound effects'),
            value: _soundOn,
            onChanged: (v) => setState(() => _soundOn = v),
          ),
          SwitchListTile(
            title: const Text('Haptic feedback (coming soon)'),
            value: _tiltControls,
            onChanged: (v) => setState(() => _tiltControls = v),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.touch_app_rounded),
            title: Text('Tap to pause'),
            subtitle: Text('Tap anywhere during a run to open the pause menu and resume or exit.'),
          ),
          const ListTile(
            leading: Icon(Icons.bolt_rounded),
            title: Text('Collectibles'),
            subtitle: Text('Coins add bonus points. Green pickups boost speed, blue pickups slow it down.'),
          ),
        ],
      ),
    );
  }
}


