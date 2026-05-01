import 'package:flutter/material.dart';

class AppColors {
  static const seedInt = 0xFF0A7E8C;
  static const seed = Color(seedInt);
  static const scaffoldBackground = Color(0xFFF4FBFB);
  static const surface = Color(0xFFFFFFFF);

  static const authGradientStart = Color(0xFFE8F6F8);
  static const authGradientMid = Color(0xFFF4FBFB);
  static const authGradientEnd = Color(0xFFD7EEF1);

  static const heatmapCompleted = Color(0xFF2FA36B);
  static const heatmapMissed = Color(0xFFDB5A42);
  static const heatmapNotScheduled = Color(0xFFD7DFE7);
  static const achievementAccent = Color(0xFFF2994A);

  static const selectedBorder = Color(0xFF000000);
  static const transparent = Color(0x00000000);
  static const white = Color(0xFFFFFFFF);

  // ── Default category colors ──────────────────────────────────────────────
  // Int literals are the single source of truth; Color constants wrap them
  // for use in Flutter widgets. Use the int variants in const lists / JSON.
  static const categoryColorHealthInt      = 0xFF2D9CDB;
  static const categoryColorFitnessInt     = 0xFF27AE60;
  static const categoryColorLearningInt    = 0xFFF2994A;
  static const categoryColorWorkInt        = 0xFF6C5CE7;
  static const categoryColorMindfulnessInt = 0xFF00B894;
  static const categoryColorPersonalInt    = 0xFFE17055;
  static const categoryColorFinanceInt     = 0xFF0984E3;

  static const categoryColorHealth      = Color(categoryColorHealthInt);
  static const categoryColorFitness     = Color(categoryColorFitnessInt);
  static const categoryColorLearning    = Color(categoryColorLearningInt);
  static const categoryColorWork        = Color(categoryColorWorkInt);
  static const categoryColorMindfulness = Color(categoryColorMindfulnessInt);
  static const categoryColorPersonal    = Color(categoryColorPersonalInt);
  static const categoryColorFinance     = Color(categoryColorFinanceInt);

  static const categoryPalette = <int>[
    0xFF0A7E8C,
    categoryColorFitnessInt,
    categoryColorHealthInt,
    categoryColorLearningInt,
    categoryColorPersonalInt,
    categoryColorWorkInt,
    categoryColorMindfulnessInt,
    categoryColorFinanceInt,
  ];
}
