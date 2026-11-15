import 'package:flutter/widgets.dart';

/// Íconos de Phosphor (https://phosphoricons.com, licencia MIT; ver
/// `assets/fonts/phosphor/LICENSE.txt`). Un solo estilo de línea, «regular», para toda la app;
/// «fill» únicamente en la pestaña activa de la barra inferior y en los marcadores del mapa.
///
/// Se usa la fuente directamente porque el paquete `phosphor_flutter` todavía no compila con
/// Flutter 3.44 o posterior (`IconData` pasó a ser final). Los puntos de código son los de la
/// versión 2.1.0 del paquete. Para agregar un ícono, busca su nombre en esa tabla.
abstract final class Phosphor {
  static const arrowClockwise = IconData(0xe036, fontFamily: 'PhosphorRegular');
  static const arrowLeft = IconData(0xe058, fontFamily: 'PhosphorRegular');
  static const arrowUp = IconData(0xe08e, fontFamily: 'PhosphorRegular');
  static const bank = IconData(0xe0b4, fontFamily: 'PhosphorRegular');
  static const barricade = IconData(0xe948, fontFamily: 'PhosphorRegular');
  static const bell = IconData(0xe0ce, fontFamily: 'PhosphorRegular');
  static const broom = IconData(0xec54, fontFamily: 'PhosphorRegular');
  static const buildings = IconData(0xe102, fontFamily: 'PhosphorRegular');
  static const calendarBlank = IconData(0xe10a, fontFamily: 'PhosphorRegular');
  static const camera = IconData(0xe10e, fontFamily: 'PhosphorRegular');
  static const cameraPlus = IconData(0xec58, fontFamily: 'PhosphorRegular');
  static const cameraSlash = IconData(0xe110, fontFamily: 'PhosphorRegular');
  static const caretDown = IconData(0xe136, fontFamily: 'PhosphorRegular');
  static const caretRight = IconData(0xe13a, fontFamily: 'PhosphorRegular');
  static const chatCircle = IconData(0xe168, fontFamily: 'PhosphorRegular');
  static const chatText = IconData(0xe17a, fontFamily: 'PhosphorRegular');
  static const chatsCircle = IconData(0xe17e, fontFamily: 'PhosphorRegular');
  static const check = IconData(0xe182, fontFamily: 'PhosphorRegular');
  static const checkCircle = IconData(0xe184, fontFamily: 'PhosphorRegular');
  static const clock = IconData(0xe19a, fontFamily: 'PhosphorRegular');
  static const clockClockwise = IconData(0xe19e, fontFamily: 'PhosphorRegular');
  static const clockCounterClockwise = IconData(0xe1a0, fontFamily: 'PhosphorRegular');
  static const cloudSlash = IconData(0xe1b6, fontFamily: 'PhosphorRegular');
  static const creditCard = IconData(0xe1d2, fontFamily: 'PhosphorRegular');
  static const crosshair = IconData(0xe1d6, fontFamily: 'PhosphorRegular');
  static const deviceMobile = IconData(0xe1e0, fontFamily: 'PhosphorRegular');
  static const downloadSimple = IconData(0xe20c, fontFamily: 'PhosphorRegular');
  static const envelope = IconData(0xe214, fontFamily: 'PhosphorRegular');
  static const eye = IconData(0xe220, fontFamily: 'PhosphorRegular');
  static const eyeSlash = IconData(0xe224, fontFamily: 'PhosphorRegular');
  static const filePdf = IconData(0xe702, fontFamily: 'PhosphorRegular');
  static const fileText = IconData(0xe23a, fontFamily: 'PhosphorRegular');
  static const flag = IconData(0xe244, fontFamily: 'PhosphorRegular');
  static const funnelSimpleX = IconData(0xe26a, fontFamily: 'PhosphorRegular');
  static const gavel = IconData(0xea32, fontFamily: 'PhosphorRegular');
  static const headset = IconData(0xe584, fontFamily: 'PhosphorRegular');
  static const house = IconData(0xe2c2, fontFamily: 'PhosphorRegular');
  static const houseLine = IconData(0xe2c4, fontFamily: 'PhosphorRegular');
  static const identificationBadge = IconData(0xe6f6, fontFamily: 'PhosphorRegular');
  static const imageBroken = IconData(0xe7a8, fontFamily: 'PhosphorRegular');
  static const images = IconData(0xe836, fontFamily: 'PhosphorRegular');
  static const info = IconData(0xe2ce, fontFamily: 'PhosphorRegular');
  static const key = IconData(0xe2d6, fontFamily: 'PhosphorRegular');
  static const listBullets = IconData(0xe2f2, fontFamily: 'PhosphorRegular');
  static const listChecks = IconData(0xeadc, fontFamily: 'PhosphorRegular');
  static const lock = IconData(0xe2fa, fontFamily: 'PhosphorRegular');
  static const lockKey = IconData(0xe2fe, fontFamily: 'PhosphorRegular');
  static const magnifyingGlass = IconData(0xe30c, fontFamily: 'PhosphorRegular');
  static const mapPin = IconData(0xe316, fontFamily: 'PhosphorRegular');
  static const mapTrifold = IconData(0xe31a, fontFamily: 'PhosphorRegular');
  static const megaphone = IconData(0xe324, fontFamily: 'PhosphorRegular');
  static const money = IconData(0xe588, fontFamily: 'PhosphorRegular');
  static const password = IconData(0xe752, fontFamily: 'PhosphorRegular');
  static const pencilSimple = IconData(0xe3b4, fontFamily: 'PhosphorRegular');
  static const phone = IconData(0xe3b8, fontFamily: 'PhosphorRegular');
  static const phoneSlash = IconData(0xe3c2, fontFamily: 'PhosphorRegular');
  static const plus = IconData(0xe3d4, fontFamily: 'PhosphorRegular');
  static const question = IconData(0xe3e8, fontFamily: 'PhosphorRegular');
  static const receipt = IconData(0xe3ec, fontFamily: 'PhosphorRegular');
  /// Robot de líneas limpias, sin cara sonriente: botón central del Asistente.
  static const robot = IconData(0xe762, fontFamily: 'PhosphorRegular');
  static const scales = IconData(0xe750, fontFamily: 'PhosphorRegular');
  static const sealCheck = IconData(0xe606, fontFamily: 'PhosphorRegular');
  static const shieldCheck = IconData(0xe40c, fontFamily: 'PhosphorRegular');
  static const signOut = IconData(0xe42a, fontFamily: 'PhosphorRegular');
  static const textAa = IconData(0xe6ee, fontFamily: 'PhosphorRegular');
  static const trash = IconData(0xe4a6, fontFamily: 'PhosphorRegular');
  static const user = IconData(0xe4c2, fontFamily: 'PhosphorRegular');
  static const userCircle = IconData(0xe4c4, fontFamily: 'PhosphorRegular');
  static const wallet = IconData(0xe68a, fontFamily: 'PhosphorRegular');
  static const warning = IconData(0xe4e0, fontFamily: 'PhosphorRegular');
  static const warningCircle = IconData(0xe4e2, fontFamily: 'PhosphorRegular');
  static const wifiSlash = IconData(0xe4f2, fontFamily: 'PhosphorRegular');
  static const x = IconData(0xe4f6, fontFamily: 'PhosphorRegular');
}

abstract final class PhosphorFill {
  static const chatCircle = IconData(0xe168, fontFamily: 'PhosphorFill');
  static const house = IconData(0xe2c2, fontFamily: 'PhosphorFill');
  static const mapPin = IconData(0xe316, fontFamily: 'PhosphorFill');
  static const megaphone = IconData(0xe324, fontFamily: 'PhosphorFill');
  static const wallet = IconData(0xe68a, fontFamily: 'PhosphorFill');
}
