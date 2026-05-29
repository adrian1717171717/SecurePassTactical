// lib/features/dashboard/presentation/pages/admin_users_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../widgets/tactical_app_bar.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // Listas por defecto en caso de que no existan en Firestore
  List<String> _companies = [
    'Dirección General',
    'Cuerpo de Oficiales',
    'Primera Compañía',
    'Segunda Compañía',
    'Tercera Compañía',
    'Cuarta Compañía',
    'Servicios Generales',
  ];

  List<String> _courses = [
    'Plana Mayor',
    'Primer Curso',
    'Segundo Curso',
    'Tercer Curso',
    'Cuarto Curso',
    'Externo',
  ];

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Cargar estructura organizativa dinámica desde Firestore
  Future<void> _loadStructure() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('metadata').doc('structure').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          if (data['companies'] != null) {
            _companies = List<String>.from(data['companies']);
          }
          if (data['courses'] != null) {
            _courses = List<String>.from(data['courses']);
          }
        });
      } else {
        // Inicializar estructura por defecto en Firestore
        await FirebaseFirestore.instance.collection('metadata').doc('structure').set({
          'companies': _companies,
          'courses': _courses,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error cargando estructura organizativa: $e');
    }
  }

  // Guardar estructura organizativa dinámica a Firestore
  Future<void> _saveStructure() async {
    try {
      await FirebaseFirestore.instance.collection('metadata').doc('structure').set({
        'companies': _companies,
        'courses': _courses,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Estructura organizativa guardada en la nube'),
            backgroundColor: AppColors.statusGranted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar estructura: $e')),
        );
      }
    }
  }

  void _showStructureManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ESTRUCTURA MILITAR (GRUPOS & CURSOS)',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestione dinámicamente las compañías, grupos o cursos de la escuela:',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  // Sección Grupos / Compañías
                  Row(
                    children: [
                      Text('COMPAÑÍAS / GRUPOS', style: AppTextStyles.labelMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        onPressed: () => _showAddDialog('Compañía / Grupo', (val) {
                          setModalState(() => _companies.add(val));
                          setState(() {});
                          _saveStructure();
                        }),
                      ),
                    ],
                  ),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: ListView.builder(
                      itemCount: _companies.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(_companies[index], style: AppTextStyles.bodyMedium),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed, size: 18),
                            onPressed: () {
                              setModalState(() => _companies.removeAt(index));
                              setState(() {});
                              _saveStructure();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sección Cursos / Subgrupos
                  Row(
                    children: [
                      Text('CURSOS / SUBGRUPOS', style: AppTextStyles.labelMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        onPressed: () => _showAddDialog('Curso / Subgrupo', (val) {
                          setModalState(() => _courses.add(val));
                          setState(() {});
                          _saveStructure();
                        }),
                      ),
                    ],
                  ),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: ListView.builder(
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(_courses[index], style: AppTextStyles.bodyMedium),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed, size: 18),
                            onPressed: () {
                              setModalState(() => _courses.removeAt(index));
                              setState(() {});
                              _saveStructure();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('FINALIZAR'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog(String label, Function(String val) onAdd) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Añadir $label', style: AppTextStyles.headlineSmall),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre de $label',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) {
                  onAdd(name);
                }
                Navigator.pop(context);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  void _showUserEditor(Map<String, dynamic> user, String uid) {
    final nameCtrl = TextEditingController(text: user['display_name'] ?? '');
    final cedulaCtrl = TextEditingController(text: user['cedula'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');

    String selectedRole = user['current_role'] ?? 'unknown';
    String selectedHierarchy = user['base_role'] ?? 'unknown';
    String selectedCompany = user['unit'] ?? (_companies.isNotEmpty ? _companies.first : '—');
    String selectedCourse = user['rank'] ?? 'ICM';
    String? selectedServiceBranch = user['service_branch'];

    List<String> getDynamicRanks(String hierarchy) {
      switch (hierarchy) {
        case 'Oficial':
          return ['Subteniente', 'Teniente', 'Capitán', 'Mayor', 'Teniente Coronel', 'Coronel', 'General'];
        case 'Voluntario':
          return ['Soldado', 'Cabo Segundo', 'Cabo Primero', 'Sargento Segundo', 'Sargento Primero', 'Suboficial Segundo', 'Suboficial Primero', 'Suboficial Mayor'];
        case 'unknown': // Cadete
          return ['ICM', 'IICM', 'IIICM', 'IVCM'];
        case 'Servidor Público':
        case 'Otro':
        default:
          return ['Ninguno', 'Civil', 'Analista', 'Especialista', 'Técnico', 'Otro'];
      }
    }

    List<String> currentRanks = getDynamicRanks(selectedHierarchy);
    if (!currentRanks.contains(selectedCourse)) {
      currentRanks.add(selectedCourse); // Keep old valid value to avoid crash initially
    }

    // Asegurar que los valores existan en las listas
    if (!_companies.contains(selectedCompany)) {
      _companies.add(selectedCompany);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('ADMINISTRAR USUARIO', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, letterSpacing: 2)),
                    const SizedBox(height: 16),

                    // Nombre
                    TextFormField(
                      controller: nameCtrl,
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Nombres completos'),
                    ),
                    const SizedBox(height: 12),

                    // Cédula y Teléfono
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cedulaCtrl,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Cédula'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Teléfono'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ROL EN LA APP (Autorizaciones operativas)
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: AppColors.surface,
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Rol Operativo en SecurPass'),
                      items: AppRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role.toFirestoreString(),
                          child: Text(role.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // JERARQUÍA MILITAR (Categoría base)
                    DropdownButtonFormField<String>(
                      value: selectedHierarchy,
                      dropdownColor: AppColors.surface,
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jerarquía Militar Base'),
                      items: const [
                        DropdownMenuItem(value: 'unknown', child: Text('Estudiante / Cadete')),
                        DropdownMenuItem(value: 'Oficial', child: Text('Oficial')),
                        DropdownMenuItem(value: 'Servidor Público', child: Text('Servidor Público')),
                        DropdownMenuItem(value: 'Voluntario', child: Text('Voluntario')),
                        DropdownMenuItem(value: 'Otro', child: Text('Externo / Otro')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedHierarchy = val;
                            currentRanks = getDynamicRanks(val);
                            selectedCourse = currentRanks.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // COMPAÑÍA / GRUPO (Dynamic units)
                    DropdownButtonFormField<String>(
                      value: selectedCompany,
                      dropdownColor: AppColors.surface,
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Compañía / Grupo (Unidad)'),
                      items: _companies.map((company) {
                        return DropdownMenuItem(
                          value: company,
                          child: Text(company),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCompany = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // CURSO / SUBGRUPO (Dynamic rank)
                    DropdownButtonFormField<String>(
                      value: selectedCourse,
                      dropdownColor: AppColors.surface,
                      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Grado / Rango'),
                      items: currentRanks.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCourse = val);
                        }
                      },
                    ),
                    
                    if (selectedHierarchy == 'Oficial' || selectedHierarchy == 'Voluntario') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedServiceBranch ?? 'Infantería',
                        dropdownColor: AppColors.surface,
                        style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Arma de Servicio'),
                        items: const [
                          DropdownMenuItem(value: 'Infantería', child: Text('Infantería')),
                          DropdownMenuItem(value: 'Caballería', child: Text('Caballería Blindada')),
                          DropdownMenuItem(value: 'Artillería', child: Text('Artillería')),
                          DropdownMenuItem(value: 'Ingenieros', child: Text('Ingenieros')),
                          DropdownMenuItem(value: 'Comunicaciones', child: Text('Comunicaciones')),
                          DropdownMenuItem(value: 'Inteligencia', child: Text('Inteligencia Militar')),
                          DropdownMenuItem(value: 'Aviación', child: Text('Aviación del Ejército')),
                          DropdownMenuItem(value: 'Especialista', child: Text('Especialista / Servicios')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedServiceBranch = val);
                        },
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Botón Guardar Cambios
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text('GUARDAR CAMBIOS', style: AppTextStyles.buttonPrimary),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Guardando cambios del usuario...')),
                          );
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'display_name': nameCtrl.text.trim(),
                              'cedula': cedulaCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'current_role': selectedRole,
                              'base_role': selectedHierarchy,
                              'unit': selectedCompany,
                              'rank': selectedCourse,
                              'service_branch': (selectedHierarchy == 'Oficial' || selectedHierarchy == 'Voluntario') ? (selectedServiceBranch ?? 'Infantería') : null,
                              'updated_at': Timestamp.now(),
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Usuario actualizado con éxito'),
                                  backgroundColor: AppColors.statusGranted,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al actualizar usuario: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance.collection('users').snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TacticalAppBar(
        title: 'ADMINISTRACIÓN',
        subtitle: 'USUARIOS Y ESTRUCTURA',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.domain_rounded, color: AppColors.primaryLight),
            onPressed: _showStructureManager,
            tooltip: 'Estructura Organizativa',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cargo o cédula...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Lista de usuarios en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium));
                }
                final docs = snapshot.data?.docs ?? [];
                
                // Filtrar usuarios localmente según búsqueda
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['display_name'] as String? ?? '').toLowerCase();
                  final rank = (data['rank'] as String? ?? '').toLowerCase();
                  final cedula = (data['cedula'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      rank.contains(_searchQuery) ||
                      cedula.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No se encontraron usuarios', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final name = data['display_name'] ?? 'Desconocido';
                    final rank = data['rank'] ?? '—';
                    final unit = data['unit'] ?? '—';
                    final currentRoleStr = data['current_role'] ?? 'unknown';
                    final role = AppRoleExtension.fromString(currentRoleStr);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.primaryLight, size: 24),
                        ),
                        title: Text(name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Compañía: $unit · Curso: $rank', style: AppTextStyles.bodySmall),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                              ),
                              child: Text(
                                role.displayName.toUpperCase(),
                                style: AppTextStyles.labelSmall.copyWith(fontSize: 8, color: AppColors.primaryLight, letterSpacing: 0.8),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                          onPressed: () => _showUserEditor(data, doc.id),
                          tooltip: 'Administrar Perfil',
                        ),
                      ),
                    ).animate(delay: (index * 20).ms).fadeIn().slideX(begin: 0.03);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
