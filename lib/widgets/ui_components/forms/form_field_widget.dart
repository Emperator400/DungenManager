import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wiederverwendbares Formular-Feld Widget
/// Unterstützt Text-, Zahlen- und Multiline-Felder
class FormFieldWidget extends StatelessWidget {
  final String label;
  final String? value;
  final Function(String) onChanged;
  final String? Function(String?)? validator;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool enabled;
  final int? maxLength;

  const FormFieldWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getFillColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        initialValue: value,
        enabled: enabled,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: _getLabelColor(context),
          ),
          prefixIcon: icon != null ? Icon(icon, color: _getIconColor(context), size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          counterText: maxLength != null ? null : '',
        ),
        style: TextStyle(
          fontSize: 15,
          color: _getTextColor(context),
        ),
        validator: validator,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Color _getFillColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  Color _getLabelColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _getIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }
}

/// Spezielles Formular-Feld für Dropdowns
class DropdownFormFieldWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? icon;
  final bool enabled;
  final String Function(T)? itemLabelBuilder;

  const DropdownFormFieldWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.icon,
    this.enabled = true,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getFillColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: _getLabelColor(context),
          ),
          prefixIcon: icon != null ? Icon(icon, color: _getIconColor(context), size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        style: TextStyle(
          fontSize: 15,
          color: _getTextColor(context),
        ),
        items: items.map((item) {
          String displayName;
          
          // Use custom label builder if provided
          if (itemLabelBuilder != null) {
            displayName = itemLabelBuilder!(item);
          } else {
            // Try to get name property from item using reflection
            try {
              final dynamicValue = item as dynamic;
              if (dynamicValue is Map && dynamicValue.containsKey('name')) {
                displayName = dynamicValue['name']?.toString() ?? item.toString();
              } else if (dynamicValue.toString().startsWith('Instance of')) {
                // For objects without toString override, try to extract name from class
                final className = dynamicValue.runtimeType.toString();
                displayName = className;
              } else {
                displayName = dynamicValue.toString();
              }
            } catch (e) {
              displayName = item.toString();
            }
          }
          
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              displayName,
              style: TextStyle(color: _getTextColor(context)),
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
      ),
    );
  }

  Color _getFillColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  Color _getLabelColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _getIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }
}

/// Container für Formular-Sektionen
class FormSectionWidget extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? borderRadius;

  const FormSectionWidget({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? _getSectionColor(context),
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: _getTitleColor(context),
                  size: 20,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getTitleColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Color _getSectionColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  Color _getTitleColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
}
