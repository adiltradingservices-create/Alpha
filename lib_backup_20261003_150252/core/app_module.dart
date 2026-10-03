import 'package:flutter/material.dart';

abstract class AppModule {
  String get moduleId;
  String get title;
  IconData get icon;

  Widget? buildTechnicianUI(BuildContext context);
  Widget? buildAdminUI(BuildContext context);
}