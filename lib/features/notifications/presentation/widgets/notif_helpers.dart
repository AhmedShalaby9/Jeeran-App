import 'package:flutter/material.dart';

IconData iconForType(String type) => switch (type) {
      'property' => Icons.home_outlined,
      'news' => Icons.article_outlined,
      'ads' => Icons.campaign_outlined,
      'project' => Icons.business_outlined,
      _ => Icons.notifications_outlined,
    };

String labelForType(String type) => switch (type) {
      'property' => 'Properties',
      'news' => 'News',
      'ads' => 'Promotions',
      'project' => 'Projects',
      _ => 'General',
    };
