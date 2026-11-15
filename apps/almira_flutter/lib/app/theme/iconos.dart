import 'package:flutter/material.dart';

/// Íconos de la app: **Material Icons de Google** (los oficiales de Android), en su versión de
/// líneas («outlined») y, para la pestaña activa de la barra inferior y los marcadores del mapa,
/// rellena («rounded»).
///
/// La clase se sigue llamando `Phosphor` y `PhosphorFill` para no romper el código existente ni
/// las ramas en curso: solo cambia qué ícono hay detrás de cada nombre. Para agregar uno, busca su
/// nombre en https://fonts.google.com/icons y úsalo con el sufijo `_outlined` (o `_rounded` si no
/// existe en líneas).
abstract final class Phosphor {
  static const arrowClockwise = Icons.refresh_rounded;
  static const arrowLeft = Icons.arrow_back_rounded;
  static const arrowUp = Icons.arrow_upward_rounded;
  static const bank = Icons.account_balance_outlined;
  static const barricade = Icons.construction_rounded;
  static const bell = Icons.notifications_none_rounded;
  static const broom = Icons.cleaning_services_outlined;
  static const buildings = Icons.apartment_rounded;
  static const calendarBlank = Icons.calendar_month_outlined;
  static const camera = Icons.photo_camera_outlined;
  static const cameraPlus = Icons.add_a_photo_outlined;
  static const cameraSlash = Icons.no_photography_outlined;
  static const caretDown = Icons.keyboard_arrow_down_rounded;
  static const caretRight = Icons.chevron_right_rounded;
  static const chatCircle = Icons.chat_bubble_outline_rounded;
  static const chatText = Icons.chat_outlined;
  static const chatsCircle = Icons.forum_outlined;
  static const check = Icons.check_rounded;
  static const checkCircle = Icons.check_circle_outline_rounded;
  static const clock = Icons.schedule_rounded;
  static const clockClockwise = Icons.update_rounded;
  static const clockCounterClockwise = Icons.history_rounded;
  static const cloudSlash = Icons.cloud_off_rounded;
  static const creditCard = Icons.credit_card_outlined;
  static const crosshair = Icons.my_location_rounded;
  static const deviceMobile = Icons.smartphone_rounded;
  static const downloadSimple = Icons.download_rounded;
  static const envelope = Icons.mail_outline_rounded;
  static const eye = Icons.visibility_outlined;
  static const eyeSlash = Icons.visibility_off_outlined;
  static const filePdf = Icons.picture_as_pdf_outlined;
  static const fileText = Icons.description_outlined;
  static const flag = Icons.flag_outlined;
  static const funnelSimpleX = Icons.filter_alt_off_outlined;
  static const gavel = Icons.gavel_rounded;
  static const headset = Icons.support_agent_rounded;
  static const house = Icons.home_outlined;
  static const houseLine = Icons.home_work_outlined;
  static const identificationBadge = Icons.badge_outlined;
  static const imageBroken = Icons.broken_image_outlined;
  static const images = Icons.photo_library_outlined;
  static const info = Icons.info_outline_rounded;
  static const key = Icons.key_rounded;
  static const listBullets = Icons.format_list_bulleted_rounded;
  static const listChecks = Icons.checklist_rounded;
  static const lock = Icons.lock_outline_rounded;
  static const lockKey = Icons.lock_person_outlined;
  static const magnifyingGlass = Icons.search_rounded;
  static const mapPin = Icons.place_outlined;
  static const mapTrifold = Icons.map_outlined;
  static const megaphone = Icons.campaign_outlined;
  static const money = Icons.payments_outlined;
  static const password = Icons.password_rounded;
  static const pencilSimple = Icons.edit_outlined;
  static const phone = Icons.call_outlined;
  static const phoneSlash = Icons.phone_disabled_outlined;
  static const plus = Icons.add_rounded;
  static const question = Icons.help_outline_rounded;
  static const receipt = Icons.receipt_long_outlined;

  /// Robot del botón central del Asistente.
  static const robot = Icons.smart_toy_outlined;
  static const scales = Icons.balance_rounded;
  static const sealCheck = Icons.verified_outlined;
  static const shieldCheck = Icons.verified_user_outlined;
  static const signOut = Icons.logout_rounded;
  static const textAa = Icons.format_size_rounded;
  static const trash = Icons.delete_outline_rounded;
  static const user = Icons.person_outline_rounded;
  static const userCircle = Icons.account_circle_outlined;
  static const wallet = Icons.account_balance_wallet_outlined;
  static const warning = Icons.warning_amber_rounded;
  static const warningCircle = Icons.error_outline_rounded;
  static const wifiSlash = Icons.wifi_off_rounded;
  static const x = Icons.close_rounded;
}

/// Versión rellena, solo para la pestaña activa y los marcadores del mapa.
abstract final class PhosphorFill {
  static const chatCircle = Icons.chat_bubble_rounded;
  static const house = Icons.home_rounded;
  static const mapPin = Icons.place_rounded;
  static const megaphone = Icons.campaign_rounded;
  static const wallet = Icons.account_balance_wallet_rounded;
}
