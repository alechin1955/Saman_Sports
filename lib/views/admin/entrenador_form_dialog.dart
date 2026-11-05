import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class EntrenadorFormDialog extends StatefulWidget {
  const EntrenadorFormDialog({
    super.key,
    required this.entrenadores,
    this.entrenador,
  });

  final AdminEntrenadorController entrenadores;
  final EntrenadorAdmin? entrenador;

  @override
  State<EntrenadorFormDialog> createState() => _EntrenadorFormDialogState();
}

class _EntrenadorFormDialogState extends State<EntrenadorFormDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _cedula;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  late final TextEditingController _clave;
  late final TextEditingController _confirmar;
  late final TextEditingController _disciplina;
  late final TextEditingController _especialidad;
  late final TextEditingController _anos;
  late final TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    final datos = widget.entrenador;
    _nombre = TextEditingController(text: datos?.nombre ?? '');
    _apellido = TextEditingController(text: datos?.apellido ?? '');
    _cedula = TextEditingController(text: datos?.cedula ?? '');
    _telefono = TextEditingController(text: datos?.telefono ?? '');
    _correo = TextEditingController(text: datos?.correo ?? '');
    _clave = TextEditingController();
    _confirmar = TextEditingController();
    _disciplina = TextEditingController(text: datos?.disciplina ?? '');
    _especialidad = TextEditingController(text: datos?.especialidad ?? '');
    _anos = TextEditingController(text: '${datos?.anosExperiencia ?? ''}');
    _descripcion = TextEditingController(text: datos?.descripcion ?? '');
  }

  @override
  void dispose() {
    for (final campo in [
      _nombre,
      _apellido,
      _cedula,
      _telefono,
      _correo,
      _clave,
      _confirmar,
      _disciplina,
      _especialidad,
      _anos,
      _descripcion,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final editando = widget.entrenador;
    final error = editando == null
        ? await widget.entrenadores.crearEntrenador(
            nombre: _nombre.text,
            apellido: _apellido.text,
            cedula: _cedula.text,
            correo: _correo.text,
            clave: _clave.text,
            confirmarClave: _confirmar.text,
            telefono: _telefono.text,
            disciplina: _disciplina.text,
            especialidad: _especialidad.text,
            anosExperiencia: int.tryParse(_anos.text.trim()) ?? -1,
            descripcion: _descripcion.text,
          )
        : await widget.entrenadores.actualizarEntrenador(
            EntrenadorAdmin(
              uid: editando.uid,
              nombre: _nombre.text.trim(),
              apellido: _apellido.text.trim(),
              disciplina: _disciplina.text.trim(),
              descripcion: _descripcion.text.trim(),
              activo: editando.activo,
              especialidad: _especialidad.text.trim(),
              anosExperiencia:
                  int.tryParse(_anos.text.trim()) ?? editando.anosExperiencia,
              correo: editando.correo,
              cedula: editando.cedula,
              telefono: _telefono.text.trim(),
            ),
          );
    if (!mounted || error != null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.entrenador != null;
    return AlertDialog(
      title: Text(
        editando ? AppStrings.editar : AppStrings.adminNuevoEntrenador,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!editando)
                Text(
                  AppStrings.adminCuentaSinCerrarSesion,
                  style: AppTextStyles.bodySmall,
                ),
              CampoTexto(label: AppStrings.nombre, controller: _nombre),
              CampoTexto(label: AppStrings.apellido, controller: _apellido),
              if (editando)
                Text('${AppStrings.cedula}: ${_cedula.text}')
              else
                CampoTexto(label: AppStrings.cedula, controller: _cedula),
              CampoTexto(label: AppStrings.telefono, controller: _telefono),
              if (editando)
                Text('${AppStrings.correoInstitucional}: ${_correo.text}')
              else
                CampoTexto(
                  label: AppStrings.correoInstitucional,
                  controller: _correo,
                ),
              if (!editando) ...[
                CampoTexto(
                  label: AppStrings.contrasena,
                  controller: _clave,
                  esContrasena: true,
                ),
                CampoTexto(
                  label: AppStrings.adminConfirmarClave,
                  controller: _confirmar,
                  esContrasena: true,
                ),
              ],
              CampoTexto(
                label: AppStrings.adminDisciplina,
                controller: _disciplina,
              ),
              CampoTexto(
                label: AppStrings.adminEspecialidad,
                controller: _especialidad,
              ),
              CampoTexto(
                label: AppStrings.adminAnosExperiencia,
                controller: _anos,
                keyboardType: TextInputType.number,
              ),
              CampoTexto(
                label: AppStrings.adminDescripcion,
                controller: _descripcion,
              ),
              if (widget.entrenadores.error != null)
                Text(widget.entrenadores.error!),
            ],
          ),
        ),
      ),
      actions: [
        BotonSecundario(
          texto: AppStrings.cancelar,
          onPressed: () => Navigator.pop(context),
        ),
        BotonPrimario(texto: AppStrings.guardar, onPressed: _guardar),
      ],
    );
  }
}
