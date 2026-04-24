import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_rate/core/common/widgets/custom_svg.dart';
import 'package:pass_rate/core/design/app_icons.dart';
import 'package:pass_rate/core/extensions/context_extensions.dart';
import '../../config/app_sizes.dart';
import '../../design/app_colors.dart';

class ReusableDatePickerField extends StatefulWidget {
  final String hintText;
  final String labelText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Color? color;
  final Widget? prefixIcon;

  const ReusableDatePickerField({
    super.key,
    required this.hintText,
    this.controller,
    this.validator,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.color = Colors.white,
    this.prefixIcon,
    required this.labelText,
  });

  @override
  State createState() => _ReusableDatePickerFieldState();
}

class _ReusableDatePickerFieldState extends State<ReusableDatePickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Use provided controller or create a new one.
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    // Dispose only if we created it.
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = widget.initialDate ?? now;
    final DateTime first = widget.firstDate ?? DateTime(1900);
    final DateTime last = widget.lastDate ?? DateTime(2100);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (pickedDate != null) {

      final String formattedDate = "${pickedDate.year}-${DateFormat('MMMM').format(pickedDate)}";
      setState(() {
        _controller.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
      child: GestureDetector(
        onTap: _selectDate,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _controller,
            validator: widget.validator,
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: context.txtTheme.headlineMedium?.copyWith(fontSize: 18),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: widget.prefixIcon,
              hintText: widget.hintText,
              hintStyle: context.txtTheme.labelSmall,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(AppSizes.iconXs),
                child: CustomSvgImage(assetName: AppIcons.calendarIcon),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
