  import 'package:flutter/material.dart';

Widget buildTextCard(BuildContext context, String label, String text,
      {double fontSize = 14, FontWeight fontWeight = FontWeight.normal}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
