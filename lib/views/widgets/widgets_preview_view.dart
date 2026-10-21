import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/auth_info_panel.dart';
import 'package:saman_sports/views/widgets/auth_split_layout.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/public_header.dart';

class WidgetsPreviewView extends StatelessWidget {
  const WidgetsPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final header = PublicHeader(linkActivo: AppStrings.inicio);
    return Scaffold(
      appBar: header,
      drawer: header.buildDrawer(context),
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
        formulario: const _FormularioPreview(),
      ),
    );
  }
}

class _FormularioPreview extends StatelessWidget {
  const _FormularioPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.iniciarSesion, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.space8),
        Text(AppStrings.loginBienvenida, style: AppTextStyles.body),
        const SizedBox(height: AppSizes.space24),
        const MensajeError(texto: AppStrings.campoObligatorio),
        const SizedBox(height: AppSizes.space16),
        const CampoTexto(
          label: AppStrings.correoInstitucional,
          hint: AppStrings.hintCorreoEstudiante,
          icono: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.space16),
        const CampoTexto(
          label: AppStrings.contrasena,
          esContrasena: true,
          icono: Icons.lock_outline,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSizes.space24),
        BotonPrimario(
          texto: AppStrings.iniciarSesion,
          onPressed: _sinAccion,
          anchoCompleto: true,
        ),
      ],
    );
  }
}

void _sinAccion() {}
