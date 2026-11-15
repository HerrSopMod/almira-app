import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Íconos de la app: **Iconsax** (https://iconsax.io, licencia MIT; paquete `iconsax_flutter`), un
/// set de trazo redondeado y formas propias, con versión de línea (`Phosphor`) y versión rellena
/// (`PhosphorFill`). La de línea va en filas, botones y campos; la rellena, en la pestaña activa,
/// los marcadores del mapa y los círculos de color (accesos de Inicio, filas del perfil).
///
/// Las clases se siguen llamando `Phosphor` y `PhosphorFill` para no romper el código existente ni
/// las ramas en curso: solo cambia qué ícono hay detrás de cada nombre. Para agregar uno, busca su
/// nombre en https://iconsax.io y usa `Iconsax.nombre_copy` (línea) o `Iconsax.nombre` (rellena).
/// La marca de verificación sigue siendo Material.
abstract final class Phosphor {
  static const check = Icons.check_rounded;
  static const arrowClockwise = Iconsax.refresh_copy;
  static const arrowLeft = Iconsax.arrow_left_copy;
  static const arrowUp = Iconsax.arrow_up_copy;
  static const bank = Iconsax.bank_copy;
  static const barricade = Iconsax.building_3_copy;
  static const bell = Iconsax.notification_copy;
  static const broom = Iconsax.brush_2_copy;
  static const buildings = Iconsax.buildings_2_copy;
  static const calendarBlank = Iconsax.calendar_1_copy;
  static const camera = Iconsax.camera_copy;
  static const cameraPlus = Iconsax.gallery_add_copy;
  static const cameraSlash = Iconsax.camera_slash_copy;
  static const caretDown = Iconsax.arrow_down_1_copy;
  static const caretRight = Iconsax.arrow_right_3_copy;
  static const chatCircle = Iconsax.message_copy;
  static const chatText = Iconsax.message_text_1_copy;
  static const chatsCircle = Iconsax.messages_2_copy;
  static const checkCircle = Iconsax.tick_circle_copy;
  static const clock = Iconsax.clock_copy;
  static const clockClockwise = Iconsax.timer_1_copy;
  static const clockCounterClockwise = Iconsax.clock_1_copy;
  static const cloudSlash = Iconsax.cloud_cross_copy;
  static const creditCard = Iconsax.card_copy;
  static const crosshair = Iconsax.gps_copy;
  static const deviceMobile = Iconsax.mobile_copy;
  static const downloadSimple = Iconsax.document_download_copy;
  static const envelope = Iconsax.sms_copy;
  static const eye = Iconsax.eye_copy;
  static const eyeSlash = Iconsax.eye_slash_copy;
  static const filePdf = Iconsax.document_download_copy;
  static const fileText = Iconsax.document_text_1_copy;
  static const flag = Iconsax.flag_copy;
  static const funnelSimpleX = Iconsax.filter_remove_copy;
  static const gavel = Iconsax.receipt_disscount_copy;
  static const headset = Iconsax.headphone_copy;
  static const house = Iconsax.home_2_copy;
  static const houseLine = Iconsax.home_hashtag_copy;
  static const identificationBadge = Iconsax.personalcard_copy;
  static const imageBroken = Iconsax.gallery_slash_copy;
  static const images = Iconsax.gallery_copy;
  static const info = Iconsax.info_circle_copy;
  static const key = Iconsax.key_copy;
  static const listBullets = Iconsax.task_square_copy;
  static const listChecks = Iconsax.clipboard_tick_copy;
  static const lock = Iconsax.lock_copy;
  static const lockKey = Iconsax.password_check_copy;
  static const magnifyingGlass = Iconsax.search_normal_1_copy;
  static const mapPin = Iconsax.location_copy;
  static const mapTrifold = Iconsax.map_1_copy;
  static const megaphone = Iconsax.message_notif_copy;
  static const money = Iconsax.money_3_copy;
  static const password = Iconsax.password_check_copy;
  static const pencilSimple = Iconsax.edit_2_copy;
  static const phone = Iconsax.call_copy;
  static const phoneSlash = Iconsax.call_slash_copy;
  static const plus = Iconsax.add_copy;
  static const question = Iconsax.message_question_copy;
  static const receipt = Iconsax.receipt_item_copy;
  static const robot = Icons.smart_toy_outlined;
  static const scales = Iconsax.judge_copy;
  static const sealCheck = Iconsax.verify_copy;
  static const shieldCheck = Iconsax.shield_tick_copy;
  static const signOut = Iconsax.logout_copy;
  static const textAa = Iconsax.text_copy;
  static const trash = Iconsax.trash_copy;
  static const user = Iconsax.user_copy;
  static const userCircle = Iconsax.profile_circle_copy;
  static const wallet = Iconsax.wallet_3_copy;
  static const warning = Iconsax.warning_2_copy;
  static const warningCircle = Iconsax.danger_copy;
  static const wifiSlash = Iconsax.wifi_square_copy;
  static const x = Iconsax.close_circle_copy;
}

/// Versión rellena de los mismos íconos.
abstract final class PhosphorFill {
  static const check = Icons.check_rounded;
  static const arrowClockwise = Iconsax.refresh;
  static const arrowLeft = Iconsax.arrow_left;
  static const arrowUp = Iconsax.arrow_up;
  static const bank = Iconsax.bank;
  static const barricade = Iconsax.building_3;
  static const bell = Iconsax.notification;
  static const broom = Iconsax.brush_2;
  static const buildings = Iconsax.buildings_2;
  static const calendarBlank = Iconsax.calendar_1;
  static const camera = Iconsax.camera;
  static const cameraPlus = Iconsax.gallery_add;
  static const cameraSlash = Iconsax.camera_slash;
  static const caretDown = Iconsax.arrow_down_1;
  static const caretRight = Iconsax.arrow_right_3;
  static const chatCircle = Iconsax.message;
  static const chatText = Iconsax.message_text_1;
  static const chatsCircle = Iconsax.messages_2;
  static const checkCircle = Iconsax.tick_circle;
  static const clock = Iconsax.clock;
  static const clockClockwise = Iconsax.timer_1;
  static const clockCounterClockwise = Iconsax.clock_1;
  static const cloudSlash = Iconsax.cloud_cross;
  static const creditCard = Iconsax.card;
  static const crosshair = Iconsax.gps;
  static const deviceMobile = Iconsax.mobile;
  static const downloadSimple = Iconsax.document_download;
  static const envelope = Iconsax.sms;
  static const eye = Iconsax.eye;
  static const eyeSlash = Iconsax.eye_slash;
  static const filePdf = Iconsax.document_download;
  static const fileText = Iconsax.document_text_1;
  static const flag = Iconsax.flag;
  static const funnelSimpleX = Iconsax.filter_remove;
  static const gavel = Iconsax.receipt_disscount;
  static const headset = Iconsax.headphone;
  static const house = Iconsax.home_2;
  static const houseLine = Iconsax.home_hashtag;
  static const identificationBadge = Iconsax.personalcard;
  static const imageBroken = Iconsax.gallery_slash;
  static const images = Iconsax.gallery;
  static const info = Iconsax.info_circle;
  static const key = Iconsax.key;
  static const listBullets = Iconsax.task_square;
  static const listChecks = Iconsax.clipboard_tick;
  static const lock = Iconsax.lock;
  static const lockKey = Iconsax.password_check;
  static const magnifyingGlass = Iconsax.search_normal_1;
  static const mapPin = Iconsax.location;
  static const mapTrifold = Iconsax.map_1;
  static const megaphone = Iconsax.message_notif;
  static const money = Iconsax.money_3;
  static const password = Iconsax.password_check;
  static const pencilSimple = Iconsax.edit_2;
  static const phone = Iconsax.call;
  static const phoneSlash = Iconsax.call_slash;
  static const plus = Iconsax.add;
  static const question = Iconsax.message_question;
  static const receipt = Iconsax.receipt_item;
  static const robot = Icons.smart_toy_rounded;
  static const scales = Iconsax.judge;
  static const sealCheck = Iconsax.verify;
  static const shieldCheck = Iconsax.shield_tick;
  static const signOut = Iconsax.logout;
  static const textAa = Iconsax.text;
  static const trash = Iconsax.trash;
  static const user = Iconsax.user;
  static const userCircle = Iconsax.profile_circle;
  static const wallet = Iconsax.wallet_3;
  static const warning = Iconsax.warning_2;
  static const warningCircle = Iconsax.danger;
  static const wifiSlash = Iconsax.wifi_square;
  static const x = Iconsax.close_circle;
}
