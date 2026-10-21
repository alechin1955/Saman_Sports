import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icono,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.helperText,
    this.esContrasena = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icono;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? helperText;
  final bool esContrasena;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late final TextEditingController _controller;
  late final bool _controlaTexto;
  bool _ocultar = true;

  @override
  void initState() {
    super.initState();
    _controlaTexto = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (_controlaTexto) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: AppSizes.space8),
        TextFormField(
          controller: _controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: widget.esContrasena && _ocultar,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            prefixIcon: widget.icono == null ? null : Icon(widget.icono),
            suffixIcon: widget.esContrasena
                ? IconButton(
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                    icon: Icon(
                      _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
