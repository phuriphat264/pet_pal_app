// lib/screens/booking_page.dart
import 'package:flutter/material.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ยืนยันการจอง")),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C3D2E), padding: const EdgeInsets.all(18)),
          child: const Text("ชำระเงิน", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("ระยะเวลา"), Text("3 คืน")]),
            Divider(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("ยอดรวม"), Text("฿1,350", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }
}