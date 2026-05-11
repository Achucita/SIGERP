import 'package:flutter/material.dart';
import '../utils/theme.dart';

// ── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'aceptada': case 'aprobado': case 'aprobada': return AppColors.statusAccepted;
      case 'pendiente': return AppColors.statusPending;
      case 'rechazada': case 'rechazado': return AppColors.statusRejected;
      case 'parcial': return AppColors.statusPartial;
      case 'final': return AppColors.statusRejected;
      default: return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'aceptada': return 'Aceptada';
      case 'aprobado': return 'Aprobado';
      case 'aprobada': return 'Aprobada';
      case 'pendiente': return 'Pendiente';
      case 'rechazada': return 'Rechazada';
      case 'rechazado': return 'Rechazado';
      case 'parcial': return 'Parcial';
      case 'final': return 'Final';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}

// ── Tech Chip ─────────────────────────────────────────────────────────────────
class TechChip extends StatelessWidget {
  final String label;
  const TechChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Text(label, style: AppTextStyles.chipLabel),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(), style: AppTextStyles.label),
  );
}

// ── Primary Button ────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkBg))
          : Text(label),
      ),
    );
  }
}

// ── App Text Field ────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? hint;
  final String? helpText;   // texto de ayuda pequeño debajo del campo
  final Widget? suffixIcon;

  const AppTextField({
    super.key, required this.label, required this.controller,
    this.obscureText = false, this.keyboardType = TextInputType.text,
    this.hint, this.helpText, this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 5),
          Text(helpText!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

// ── App Dropdown ──────────────────────────────────────────────────────────────
class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const AppDropdown({
    super.key, required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: AppColors.darkCard,
          style: AppTextStyles.body,
          decoration: const InputDecoration(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusRejected.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusRejected.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.statusRejected, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
          style: const TextStyle(color: AppColors.statusRejected, fontSize: 13))),
      ]),
    );
  }
}

// ── Loading Screen ────────────────────────────────────────────────────────────
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}