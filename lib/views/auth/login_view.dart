import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/validators.dart';
import 'package:saman_sports/views/widgets/auth_info_panel.dart';
import 'package:saman_sports/views/widgets/auth_split_layout.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';
import 'package:saman_sports/views/widgets/enlace_volver_inicio.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _recordar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.reiniciarEstado();
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthSplitLayout(
        panelIzquierdo: const AuthInfoPanel(
          tagline: AppStrings.loginTagline,
          palabraResaltada: AppStrings.loginPalabraResaltada,
          descripcion: AppStrings.loginDescripcion,
          features: [
            AuthFeature(
              icono: Icons.calendar_today_outlined,
              titulo: AppStrings.featureReservas,
              texto: AppStrings.featureReservasTexto,
            ),
            AuthFeature(
              icono: Icons.people_outline,
              titulo: AppStrings.featureComunidad,
              texto: AppStrings.featureComunidadTexto,
            ),
            AuthFeature(
              icono: Icons.emoji_events_outlined,
              titulo: AppStrings.featureEquipos,
              texto: AppStrings.featureEquiposTexto,
            ),
          ],
        ),
        formulario: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Form(
              key: _formKey,
              child: _LoginForm(
                controller: widget.controller,
                correo: _correo,
                clave: _clave,
                recordar: _recordar,
                onRecordar: (valor) => setState(() => _recordar = valor),
                onEnviar: _enviar,
                onOlvido: _irARecuperar,
                onRegistro: _irARegistro,
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
    final destino = await widget.controller.iniciarSesion(
      _correo.text,
      _clave.text,
      recordar: _recordar,
    );
    if (!mounted || destino == null) {
      return;
    }
    Navigator.pushReplacementNamed(context, _rutaDe(destino));
  }

  void _irARecuperar() {
    Navigator.pushNamed(
      context,
      AppRoutes.recuperarContrasena,
      arguments: _correo.text,
    );
  }

  void _irARegistro() {
    Navigator.pushNamed(context, AppRoutes.registro);
  }

  String _rutaDe(DestinoLogin destino) {
    return switch (destino) {
      DestinoLogin.estudiante => AppRoutes.dashboardEstudiante,
      DestinoLogin.entrenador => AppRoutes.dashboardEntrenador,
      DestinoLogin.administrador => AppRoutes.dashboardAdmin,
    };
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.controller,
    required this.correo,
    required this.clave,
    required this.recordar,
    required this.onRecordar,
    required this.onEnviar,
    required this.onOlvido,
    required this.onRegistro,
  });

  final AuthController controller;
  final TextEditingController correo;
  final TextEditingController clave;
  final bool recordar;
  final ValueChanged<bool> onRecordar;
  final VoidCallback onEnviar;
  final VoidCallback onOlvido;
  final VoidCallback onRegistro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EnlaceVolverInicio(),
        const SizedBox(height: AppSizes.space16),
        Text(AppStrings.iniciarSesion, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.space8),
        Text(
          AppStrings.loginBienvenida,
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
          hint: AppStrings.hintCorreoEstudiante,
          helperText: AppStrings.ayudaCorreoLogin,
          icono: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.correoInstitucional,
        ),
        const SizedBox(height: AppSizes.space16),
        CampoTexto(
          controller: clave,
          label: AppStrings.contrasena,
          icono: Icons.lock_outline,
          esContrasena: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onEnviar(),
          validator: Validators.clave,
        ),
        const SizedBox(height: AppSizes.space8),
        _RecordarYOlvido(
          recordar: recordar,
          onRecordar: onRecordar,
          onOlvido: onOlvido,
        ),
        const SizedBox(height: AppSizes.space16),
        BotonPrimario(
          texto: AppStrings.iniciarSesion,
          onPressed: onEnviar,
          cargando: controller.cargando,
          anchoCompleto: true,
        ),
        const SizedBox(height: AppSizes.space24),
        const _DivisorO(),
        const SizedBox(height: AppSizes.space16),
        _CrearCuenta(onRegistro: onRegistro),
      ],
    );
  }
}

class _RecordarYOlvido extends StatelessWidget {
  const _RecordarYOlvido({
    required this.recordar,
    required this.onRecordar,
    required this.onOlvido,
  });

  final bool recordar;
  final ValueChanged<bool> onRecordar;
  final VoidCallback onOlvido;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: recordar,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (valor) => onRecordar(valor ?? false),
            ),
            Text(AppStrings.recordarSesion, style: AppTextStyles.bodySmall),
          ],
        ),
        TextButton(onPressed: onOlvido, child: Text(AppStrings.olvidasteContrasena)),
      ],
    );
  }
}

class _DivisorO extends StatelessWidget {
  const _DivisorO();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space8),
          child: Text(
            AppStrings.divisorO,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _CrearCuenta extends StatelessWidget {
  const _CrearCuenta({required this.onRegistro});

  final VoidCallback onRegistro;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(AppStrings.noTienesCuenta, style: AppTextStyles.bodySmall),
            TextButton(onPressed: onRegistro, child: Text(AppStrings.registrate)),
          ],
        ),
        Text(
          AppStrings.registroSoloEstudiantes,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
