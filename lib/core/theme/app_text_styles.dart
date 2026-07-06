import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Heading
  static TextStyle get h1 => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground);
  static TextStyle get h2 => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground);
  static TextStyle get h3 => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground);

  // Body
  static TextStyle get body     => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.foreground);
  static TextStyle get bodyMd   => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground);
  static TextStyle get caption  => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.mutedFg);
  static TextStyle get label    => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mutedFg, letterSpacing: 0.5);

  // Mono – dùng cho số tiền, mã hóa đơn, ngày
  static TextStyle get mono     => GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.foreground);
  static TextStyle get monoLg   => GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground);
  static TextStyle get monoSm   => GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.mutedFg);
}
