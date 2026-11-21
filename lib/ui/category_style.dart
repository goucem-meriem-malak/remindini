import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../models/subscription.dart';

class CatStyle {
  const CatStyle(this.icon, this.a, this.b);
  final IconData icon;
  final Color a, b;
  LinearGradient get gradient => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]);
}

CatStyle catStyle(Category c) => switch (c) {
      Category.streaming => const CatStyle(Icons.play_circle_rounded, Color(0xFFFF8AB8), Color(0xFFF2457F)),
      Category.music => const CatStyle(Icons.music_note_rounded, Color(0xFFFFB56B), Color(0xFFF2761F)),
      Category.gaming => const CatStyle(Icons.sports_esports_rounded, Color(0xFF8FA2FF), Color(0xFF4F5CF0)),
      Category.software => const CatStyle(Icons.apps_rounded, Color(0xFF6CC8FF), Color(0xFF2B8CF0)),
      Category.cloud => const CatStyle(Icons.cloud_rounded, Color(0xFF4FE3C8), Color(0xFF14A88C)),
      Category.news => const CatStyle(Icons.newspaper_rounded, Color(0xFF9AA6CC), Color(0xFF5B6896)),
      Category.fitness => const CatStyle(Icons.fitness_center_rounded, Color(0xFF7BE495), Color(0xFF22A855)),
      Category.education => const CatStyle(Icons.school_rounded, Color(0xFFFFC857), Color(0xFFF08C10)),
      Category.utilities => const CatStyle(Icons.bolt_rounded, Color(0xFFB79CFF), Color(0xFF6D48EC)),
      Category.other => const CatStyle(Icons.category_rounded, Color(0xFFA7AFD0), Color(0xFF6A7298)),
    };

String catLabel(S s, Category c) => s.t('cat_${c.name}');
