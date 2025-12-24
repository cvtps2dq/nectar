import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'contact_list.dart';
import 'chat_area.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      body: Row(
        children: [
          // Sidebar
          const SizedBox(
            width: 320,
            child: ContactList(),
          ),
          
          // Vertical Divider (Neumorphic Groove)
          Container(
            width: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [NeuColors.shadowDark, NeuColors.shadowLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // Chat Area
          const Expanded(
            child: ChatArea(),
          ),
        ],
      ),
    );
  }
}