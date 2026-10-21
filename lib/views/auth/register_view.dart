import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/datos_registro.dart';
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

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.controller});

  final AuthController controller;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _cedula = TextEditingController();
  final _carnet = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  bool _aceptaTerminos = false;
  bool _errorTerminos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.reiniciarEstado();
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _cedula.dispose();
    _carnet.dispose();
    _telefono.dispose();
    _correo.dispose();
    _clave.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthSplitLayout(
        panelIzquierdo: const AuthInfoPanel(
          tagline: AppStrings.registroTaglineCompleta,
          palabraResaltada: AppStrings.registroTaglineDestacado,
          descripcion: AppStrings.registroDescripcion,
          features: [
            AuthFeature(
              icono: Icons.emoji_events_outlined,
              titulo: AppStrings.featureDescubre,
              texto: AppStrings.featureDescubreTexto,
            ),
            AuthFeature(
              icono: Icons.calendar_today_outlined,
              titulo: AppStrings.featureAgenda,
              texto: AppStrings.featureAgendaTexto,
            ),
            AuthFeature(
              icono: Icons.people_outline,
              titulo: AppStrings.featureComunidad,
              texto: AppStrings.featureComunidadRegistroTexto,
            ),
          ],
        ),
        formulario: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Form(
              key: _formKey,
              child: _RegisterForm(
                controller: widget.controller,
                nombre: _nombre,
                apellido: _apellido,
                cedula: _cedula,
                carnet: _carnet,
                telefono: _telefono,
                correo: _correo,
                clave: _clave,
                confirmar: _confirmar,
                aceptaTerminos: _aceptaTerminos,
                errorTerminos: _errorTerminos,
                onTerminos: (valor) => setState(() {
                  _aceptaTerminos = valor;
                  _errorTerminos = false;
                }),
                onProximamente: _proximamente,
                onEnviar: _enviar,
                onLogin: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    final formularioValido = _formKey.currentState?.validate() ?? false;
    if (!_aceptaTerminos) {
      setState(() => _errorTerminos = true);
    }
    if (!formularioValido || !_aceptaTerminos) {
      return;
    }

    widget.controller.limpiarError();
    final registrado = await widget.controller.registrarEstudiante(
      DatosRegistro(
        nombre: _nombre.text,
        apellido: _apellido.text,
        cedula: _cedula.text,
        carnet: _carnet.text,
        telefono: _telefono.text,
        correo: _correo.text,
        clave: _clave.text,
      ),
    );
    if (!mounted || !registrado) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.dashboardEstudiante);
  }

  void _proximamente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.proximamente)),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.controller,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.carnet,
    required this.telefono,
    required this.correo,
    required this.clave,
    required this.confirmar,
    required this.aceptaTerminos,
    required this.errorTerminos,
    required this.onTerminos,
    required this.onProximamente,
    required this.onEnviar,
    required this.onLogin,
  });

  final AuthController controller;
  final TextEditingController nombre;
  final TextEditingController apellido;
  final TextEditingController cedula;
  final TextEditingController carnet;
  final TextEditingController telefono;
  final TextEditingController correo;
  final TextEditingController clave;
  final TextEditingController confirmar;
  final bool aceptaTerminos;
  final bool errorTerminos;
  final ValueChanged<bool> onTerminos;
  final VoidCallback onProximamente;
  final VoidCallback onEnviar;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final enFila = MediaQuery.sizeOf(context).width >= AppSizes.desktop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EnlaceVolverInicio(),
        const SizedBox(height: AppSizes.space16),
        Text(AppStrings.crearCuenta, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.space8),
        Text(
          AppStrings.registroSubtitulo,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.space24),
        if (controller.error != null) ...[
          MensajeError(texto: controller.error!),
          const SizedBox(height: AppSizes.space16),
        ],
        _ParCampos(
          enFila: enFila,
          primero: CampoTexto(
            controller: nombre,
            label: AppStrings.nombre,
            icono: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: Validators.nombre,
          ),
          segundo: CampoTexto(
            controller: apellido,
            label: AppStrings.apellido,
            textInputAction: TextInputAction.next,
            validator: Validators.apellido,
          ),
        ),
        const SizedBox(height: AppSizes.space16),
        _ParCampos(
          enFila: enFila,
          primero: CampoTexto(
            controller: cedula,
            label: AppStrings.cedula,
            hint: AppStrings.hintCedula,
            icono: Icons.badge_outlined,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: Validators.cedula,
          ),
          segundo: CampoTexto(
            controller: carnet,
            label: AppStrings.carnet,
            hint: AppStrings.hintCarnet,
            icono: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: Validators.carnet,
          ),
        ),
        const SizedBox(height: AppSizes.space16),
        CampoTexto(
          controller: telefono,
          label: AppStrings.telefono,
          hint: AppStrings.hintTelefono,
          icono: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: Validators.telefono,
        ),
        const SizedBox(height: AppSizes.space16),
        CampoTexto(
          controller: correo,
          label: AppStrings.correoInstitucional,
          hint: AppStrings.hintCorreoRegistro,
          helperText: AppStrings.ayudaCorreoRegistro,
          icono: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.correoEstudiante,
        ),
        const SizedBox(height: AppSizes.space16),
        _ParCampos(
          enFila: enFila,
          primero: CampoTexto(
            controller: clave,
            label: AppStrings.contrasena,
            hint: AppStrings.hintContrasena,
            icono: Icons.lock_outline,
            esContrasena: true,
            textInputAction: TextInputAction.next,
            validator: Validators.clave,
          ),
          segundo: CampoTexto(
            controller: confirmar,
            label: AppStrings.confirmarContrasena,
            hint: AppStrings.repetirContrasena,
            icono: Icons.lock_outline,
            esContrasena: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onEnviar(),
            validator: (valor) => Validators.confirmarClave(valor, clave.text),
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        _Terminos(
          acepta: aceptaTerminos,
          mostrarError: errorTerminos,
          onChanged: onTerminos,
          onLink: onProximamente,
        ),
        const SizedBox(height: AppSizes.space16),
        BotonPrimario(
          texto: AppStrings.crearCuenta,
          icono: Icons.arrow_forward,
          onPressed: onEnviar,
          cargando: controller.cargando,
          anchoCompleto: true,
        ),
        const SizedBox(height: AppSizes.space16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(AppStrings.yaTienesCuenta, style: AppTextStyles.bodySmall),
            TextButton(onPressed: onLogin, child: Text(AppStrings.iniciarSesion)),
          ],
        ),
      ],
    );
  }
}

class _ParCampos extends StatelessWidget {
  const _ParCampos({
    required this.enFila,
    required this.primero,
    required this.segundo,
  });

  final bool enFila;
  final Widget primero;
  final Widget segundo;

  @override
  Widget build(BuildContext context) {
    if (!enFila) {
      return Column(
        children: [
          primero,
          const SizedBox(height: AppSizes.space16),
          segundo,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: primero),
        const SizedBox(width: AppSizes.space12),
        Expanded(child: segundo),
      ],
    );
  }
}

class _Terminos extends StatelessWidget {
  const _Terminos({
    required this.acepta,
    required this.mostrarError,
    required this.onChanged,
    required this.onLink,
  });

  final bool acepta;
  final bool mostrarError;
  final ValueChanged<bool> onChanged;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: acepta,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (valor) => onChanged(valor ?? false),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(AppStrings.aceptoLos, style: AppTextStyles.bodySmall),
                  TextButton(onPressed: onLink, child: Text(AppStrings.terminosCondiciones)),
                  Text(AppStrings.yLa, style: AppTextStyles.bodySmall),
                  TextButton(onPressed: onLink, child: Text(AppStrings.politicaPrivacidad)),
                ],
              ),
            ),
          ],
        ),
        if (mostrarError)
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.space12),
            child: Text(
              AppStrings.debesAceptarTerminos,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
