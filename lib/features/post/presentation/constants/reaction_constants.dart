import 'package:flutter/material.dart';

class Reaction {
  final String name;
  final String emoji;
  final String code;
  final Color color;

  const Reaction({
    required this.name,
    required this.emoji,
    required this.code,
    required this.color,
  });
}

const List<Reaction> postReactions = [
  Reaction(
    name: 'Like',
    emoji: 'https://hr-screening.s3.ap-south-1.amazonaws.com/test%20open%20files%20upload/likedIcon.svg_1740128322035',
    code: 'Like',
    color: Color(0xFF0A66C2),
  ),
  Reaction(
    name: 'Celebrate',
    emoji: 'https://hr-screening.s3.ap-south-1.amazonaws.com/test%20open%20files%20upload/celebrateIcon.svg_1740128322034',
    code: 'celebrate',
    color: Color(0xFF44712E),
  ),
  Reaction(
    name: 'Support',
    emoji: 'https://hr-screening.s3.ap-south-1.amazonaws.com/test%20open%20files%20upload/supportIcon.svg_1740128322034',
    code: 'support',
    color: Color(0xFF715E86),
  ),
  Reaction(
    name: 'Love',
    emoji: 'https://hr-screening.s3.ap-south-1.amazonaws.com/test%20open%20files%20upload/loveIcon.svg_1740128322032',
    code: 'love',
    color: Color(0xFFB24020),
  ),
  Reaction(
    name: 'Insightful',
    emoji: 'https://hr-screening.s3.ap-south-1.amazonaws.com/test%20open%20files%20upload/insightfulIcon.svg_1740128322032',
    code: 'insightful',
    color: Color(0xFF915907),
  ),
  Reaction(
    name: 'Laugh',
    emoji: 'https://hr-screening.s3.ap-south-1.amazonaws.com/test%20open%20files%20upload/laughIcon.svg_1740128322030',
    code: 'laugh',
    color: Color(0xFF1A707E),
  ),
];
