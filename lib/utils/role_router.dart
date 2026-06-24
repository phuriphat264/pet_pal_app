// Picks which app shell to show after login, based on the signed-in user's
// role.
import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/admin_dashboard_page.dart';
import '../screens/technician_camera_page.dart';

Widget homeForRole(String? role) {
  switch (role) {
    case 'admin':
      return const AdminDashboardPage();
    case 'technician':
      return const TechnicianCameraPage();
    default:
      return const MainNavigation();
  }
}
