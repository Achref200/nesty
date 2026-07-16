import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Nesty's icon vocabulary — modern, thin-line Lucide glyphs mapped to semantic
/// names. Screens reference [AppIcons] rather than raw icon constants, so the
/// whole product speaks one visual language and can be restyled in one place.
abstract final class AppIcons {
  // Navigation
  static const IconData explore = LucideIcons.search;
  static const IconData home = LucideIcons.home;
  static const IconData saved = LucideIcons.heart;
  static const IconData trips = LucideIcons.luggage;
  static const IconData profile = LucideIcons.user;
  static const IconData dashboard = LucideIcons.activity;
  static const IconData calendar = LucideIcons.calendarDays;
  static const IconData listings = LucideIcons.building2;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData minus = LucideIcons.minus;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checkAll = LucideIcons.checkCheck;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData forward = LucideIcons.arrowRight;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData trash = LucideIcons.trash2;
  static const IconData send = LucideIcons.send;
  static const IconData swap = LucideIcons.arrowRightLeft;

  // Property facts
  static const IconData location = LucideIcons.mapPin;
  static const IconData bed = LucideIcons.bedDouble;
  static const IconData bath = LucideIcons.bath;
  static const IconData area = LucideIcons.ruler;
  static const IconData star = LucideIcons.star;
  static const IconData tour3d = LucideIcons.box;
  static const IconData wifi = LucideIcons.wifi;

  // Rooms
  static const IconData room = LucideIcons.doorOpen;
  static const IconData living = LucideIcons.sofa;
  static const IconData kitchen = LucideIcons.utensils;
  static const IconData bathroom = LucideIcons.showerHead;

  // Reservations
  static const IconData visit = LucideIcons.calendarClock;
  static const IconData stay = LucideIcons.calendarDays;
  static const IconData guests = LucideIcons.users;
  static const IconData confirmed = LucideIcons.calendarCheck;
  static const IconData celebrate = LucideIcons.partyPopper;
  static const IconData clock = LucideIcons.clock;

  // Roles / people
  static const IconData seeker = LucideIcons.search;
  static const IconData agency = LucideIcons.building2;
  static const IconData verified = LucideIcons.badgeCheck;

  // Profile / meta
  static const IconData bell = LucideIcons.bell;
  static const IconData settings = LucideIcons.settings;
  static const IconData signOut = LucideIcons.logOut;
  static const IconData shield = LucideIcons.shieldCheck;
  static const IconData help = LucideIcons.info;
  static const IconData about = LucideIcons.sparkles;
  static const IconData mail = LucideIcons.mail;
  static const IconData lock = LucideIcons.lock;
  static const IconData eye = LucideIcons.eye;

  // Cover / media
  static const IconData image = LucideIcons.image;
  static const IconData camera = LucideIcons.camera;
}
