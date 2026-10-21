import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/validators.dart';
import 'package:saman_sports/views/widgets/auth_info_panel.dart';
import 'package:saman_sports/views/widgets/auth_split_layout.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';
import 'package:saman_sports/views/widgets/enlace_volver_inicio.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({
    super.key,
    required this.controller,
    this.correoInicial,
  });

  final AuthController controller;
  final String? correoInicial;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correo;

  @override
  void initState() {
    super.initState();
    _correo = TextEditingController(text: widget.correoInicial ?? '');
  }

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthSplitLayout(
        panelIzquierdo: const AuthInfoPanel(
          tagline: AppStrings.recuperarTaglineCompleta,
          palabraResaltada: AppStrings.recuperarPalabraResaltada,
          descripcion: AppStrings.recuperarPanelDescripcion,
          features: [
            AuthFeature(
              icono: Icons.mail_outline,
              titulo: AppStrings.featureEnlace,
              texto: AppStrings.featureEnlaceTexto,
            ),
            AuthFeature(
              icono: Icons.verified_user_outlined,
              titulo: AppStrings.featureProceso,
              texto: AppStrings.featureProcesoTexto,
            ),
            AuthFeature(
              icono: Icons.key_outlined,
              titulo: AppStrings.featureNuevaClave,
              texto: AppStrings.featureNuevaClaveTexto,
            ),
          ],
        ),
        formulario: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.enlaceEnviado) {
              return _ConfirmacionRecuperacion(
                controller: widget.controller,
                onLogin: _irALogin,
                onReenviar: _reenviar,
              );
            }
            return Form(
              key: _formKey,
              child: _FormularioRecuperacion(
                controller: widget.controller,
                correo: _correo,
                onEnviar: _enviar,
                onLogin: _irALogin,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    widget.controller.limpiarError();
    await widget.controller.enviarEnlaceRecuperacion(_correo.text);
  }

  Future<void> _reenviar() async {
    await widget.controller.reenviarEnlace();
    if (!mounted || widget.controller.error != null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.enlaceReenviado)),
    );
  }

  void _irALogin() {
    Navigator.pushNamed(context, AppRoutes.login);
  }
}

class _FormularioRecuperacion extends StatelessWidget {
  const _FormularioRecuperacion({
    required this.controller,
    required this.correo,
    required this.onEnviar,
    required this.onLogin,
  });

  final AuthController controller;
  final TextEditingController correo;
  final VoidCallback onEnviar;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnlaceVolverInicio(
          texto: AppStrings.volverAIniciarSesion,
          onPressed: onLogin,
        ),
        const SizedBox(height: AppSizes.space24),
        Text(AppStrings.recuperarContrasena, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.space8),
        Text(
          AppStrings.recuperarDescripcion,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.space24),
        if (controller.error != null) ...[
          MensajeError(texto: controller.error!),
          const SizedBox(height: AppSizes.space16),
        ],
        CampoTexto(
          controller: correo,
          label: AppStrings.correoInstitucional,
          hint: AppStrings.hintCorreoRegistro,
          icono: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onEnviar(),
          validator: Validators.correoInstitucional,
        ),
        const SizedBox(height: AppSizes.space16),
        BotonPrimario(
          texto: AppStrings.enviarEnlace,
          icono: Icons.arrow_forward,
          onPressed: onEnviar,
          cargando: controller.cargando,
          anchoCompleto: true,
        ),
        const SizedBox(height: AppSizes.space16),
        const _NotaEnlace(),
        const SizedBox(height: AppSizes.space24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(AppStrings.recordasteContrasena, style: AppTextStyles.bodySmall),
            TextButton(onPressed: onLogin, child: Text(AppStrings.iniciarSesion)),
          ],
        ),
      ],
    );
  }
}

class _ConfirmacionRecuperacion extends StatelessWidget {
  const _ConfirmacionRecuperacion({
    required this.controller,
    required this.onLogin,
    required this.onReenviar,
  });

  final AuthController controller;
  final VoidCallback onLogin;
  final VoidCallback onReenviar;

  @override
  Widget build(BuildContext context) {
    final esperando = controller.segundosReenvio > 0;
    return Column(
      children: [
        const _IconoCorreo(),
        const SizedBox(height: AppSizes.space24),
        Text(
          AppStrings.revisarCorreo,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSizes.space12),
        Text.rich(
          TextSpan(
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            children: [
              const TextSpan(text: AppStrings.mensajeAntesCorreo),
              TextSpan(
                text: controller.correoEnviado ?? '',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: AppStrings.mensajeDespuesCorreo),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.space24),
        BotonPrimario(
          texto: AppStrings.volverAIniciarSesion,
          onPressed: onLogin,
          anchoCompleto: true,
        ),
        const SizedBox(height: AppSizes.space12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSizes.space8,
          runSpacing: AppSizes.space8,
          children: [
            BotonSecundario(
              texto: AppStrings.reenviarEnlace,
              onPressed: esperando ? null : onReenviar,
            ),
            if (esperando) _Contador(segundos: controller.segundosReenvio),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSizes.space8),
            Text(AppStrings.escribisteMalCorreo, style: AppTextStyles.bodySmall),
            TextButton(
              onPressed: controller.usarOtroCorreo,
              child: Text(AppStrings.usarOtroCorreo),
            ),
          ],
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.segundos});

  final int segundos;

  @override
  Widget build(BuildContext context) {
    final minutos = segundos ~/ 60;
    final resto = (segundos % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space12,
        vertical: AppSizes.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.space32),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '${AppStrings.disponibleEn} $minutos:$resto',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _NotaEnlace extends StatelessWidget {
  const _NotaEnlace();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.space8),
          Expanded(
            child: Text(
              AppStrings.avisoEnlace,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconoCorreo extends StatelessWidget {
  const _IconoCorreo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.iconCircle,
      height: AppSizes.iconCircle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: AppSizes.iconCircle,
            height: AppSizes.iconCircle,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline,
              color: AppColors.primary,
              size: AppSizes.iconLarge,
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: AppSizes.iconMedium,
            ),
          ),
        ],
      ),
    );
  }
}
