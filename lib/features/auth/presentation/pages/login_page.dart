// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../routing/route_names.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _customRankCtrl = TextEditingController();
  String _selectedRank = 'Cadete';
  String _selectedCompany = 'ICM';
  
  bool _isLoading = false;
  bool _obscure = true;
  bool _isRegistering = false;
  String? _error;
  String? _loadingStatus;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _cedulaCtrl.dispose();
    _phoneCtrl.dispose();
    _customRankCtrl.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('user-not-found')) {
      return '✗ USUARIO NO REGISTRADO — Active el modo de pruebas abajo y regístrese.';
    }
    if (str.contains('wrong-password') || str.contains('invalid-credential') || str.contains('invalid-email')) {
      return '✗ CREDENCIALES INCORRECTAS — Correo o contraseña inválida.';
    }
    if (str.contains('network-request-failed') || str.contains('TimeoutException')) {
      return '✗ ERROR DE CONEXIÓN — El servidor de seguridad no responde. Verifique su internet.';
    }
    if (str.contains('email-already-in-use')) {
      return '✗ REGISTRO RECHAZADO — Este correo ya se encuentra registrado.';
    }
    if (str.contains('weak-password')) {
      return '✗ SEGURIDAD INSUFICIENTE — La contraseña debe ser de al menos 6 caracteres.';
    }
    if (str.contains('permission-denied')) {
      return '✗ ACCESO DENEGADO — Error de reglas en Firestore o base de datos no configurada.';
    }
    if (str.contains('operation-not-allowed')) {
      return '✗ OPERACIÓN RECHAZADA — Habilite "Correo y Contraseña" en Authentication en la Consola.';
    }
    return '✗ ERROR DE SEGURIDAD: ${str.replaceAll('FirebaseException:', '').replaceAll('FirebaseAuthException:', '').replaceAll('Exception:', '').trim()}';
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { 
      _isLoading = true; 
      _error = null; 
      _loadingStatus = 'CONECTANDO CON SERVIDORES SECURPASS...';
    });
    try {
      final signIn = ref.read(signInProvider);
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _loadingStatus = 'VERIFICANDO CREDENCIALES INSTITUCIONALES...');
      
      await signIn(_emailCtrl.text.trim(), _passCtrl.text);
      
      if (!mounted) return;
      setState(() => _loadingStatus = 'SESIÓN AUTORIZADA — OBTENIENDO PERFIL...');
      await Future.delayed(const Duration(milliseconds: 400));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ INICIO DE SESIÓN EXITOSO — Bienvenido'),
            backgroundColor: AppColors.statusGranted,
            duration: Duration(seconds: 2),
          ),
        );
        context.go(RouteNames.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { 
      _isLoading = true; 
      _error = null; 
      _loadingStatus = 'CONECTANDO CON REGISTRO DE SEGURIDAD...';
    });
    try {
      final signUp = ref.read(signUpProvider);
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _loadingStatus = 'CREANDO PERFIL OPERATIVO EN FIRESTORE...');
      
      final finalRank = _selectedRank == 'Otro' 
          ? _customRankCtrl.text.trim() 
          : _selectedRank;

      await signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text.trim().toUpperCase(),
        cedula: _cedulaCtrl.text.trim(),
        rank: finalRank.isEmpty ? 'Cadete' : finalRank,
        phone: _phoneCtrl.text.trim(),
        unit: _selectedRank == 'Cadete' ? _selectedCompany : '',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ REGISTRO EXITOSO — Perfil operativo inicializado'),
            backgroundColor: AppColors.statusGranted,
            duration: Duration(seconds: 3),
          ),
        );
        context.go(RouteNames.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recoverPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = '✗ CORREO REQUERIDO — Ingrese su correo en el campo superior para enviarle el enlace de recuperación.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _loadingStatus = 'ENVIANDO ENLACE DE RECUPERACIÓN...';
    });
    
    try {
      final recover = ref.read(recoverPasswordProvider);
      await recover(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ENLACE ENVIADO — Se envió un correo de recuperación a $email'),
            backgroundColor: AppColors.statusGranted,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050810), Color(0xFF0A0E14), Color(0xFF0D1520)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Fondo — Grid táctico ────────────────────────
            Positioned.fill(child: _TacticalGridBackground()),

            // ── Contenido ───────────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 460 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Emblema
                      _buildLogo()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 40),

                      // Card de login
                      _buildLoginCard()
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Escudo táctico
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            color: AppColors.primaryGlow,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text('SECURPASS', style: AppTextStyles.displayLarge),
        Text(
          'SISTEMA DE CONTROL DE ACCESOS',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryGlow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Text(
            'TACTICAL v1.0',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isRegistering ? 'REGISTRO DE CUENTA' : 'AUTENTICACIÓN', style: AppTextStyles.labelMedium.copyWith(
              letterSpacing: 3,
              color: AppColors.primary,
            )),
            const SizedBox(height: 4),
            Text(_isRegistering ? 'Registre un nuevo correo para pruebas' : 'Ingrese sus credenciales institucionales',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 28),

            // ── Email ──────────────────────────────────────
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                prefixIcon: Icon(Icons.alternate_email_rounded,
                    color: AppColors.textMuted),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Correo inválido' : null,
            ),
            const SizedBox(height: 16),

            // ── Contraseña ─────────────────────────────────
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Contraseña muy corta' : null,
              onFieldSubmitted: (_) => _isRegistering ? _signUp() : _signIn(),
            ),

            if (!_isRegistering) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _recoverPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '¿Olvidó su contraseña?',
                    style: AppTextStyles.buttonSecondary.copyWith(
                      fontSize: 12,
                      color: AppColors.primaryLight.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],

            if (_isRegistering) ...[
              const SizedBox(height: 16),

              // ── Nombres Completos ──────────────────────────
              TextFormField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyLarge,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'NOMBRES COMPLETOS (APELLIDOS NOMBRES)',
                  hintText: 'Ej. MORALES ADRIÁN',
                  helperText: 'Registre sus Apellidos y Nombres en mayúsculas',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppColors.textMuted),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese sus nombres completos' : null,
              ),
              const SizedBox(height: 16),

              // ── Número de Cédula ───────────────────────────
              TextFormField(
                controller: _cedulaCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Número de cédula',
                  prefixIcon: Icon(Icons.badge_outlined,
                      color: AppColors.textMuted),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 8) ? 'Ingrese una cédula válida' : null,
              ),
              const SizedBox(height: 16),

              // ── Cargo / Jerarquía (Dropdown) ───────────────
              DropdownButtonFormField<String>(
                value: _selectedRank,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Cargo o Jerarquía',
                  prefixIcon: Icon(Icons.grade_outlined,
                      color: AppColors.textMuted),
                ),
                items: const [
                  DropdownMenuItem(value: 'Oficial', child: Text('Oficial')),
                  DropdownMenuItem(value: 'Servidor Público', child: Text('Servidor Público')),
                  DropdownMenuItem(value: 'Cadete', child: Text('Cadete')),
                  DropdownMenuItem(value: 'Voluntario', child: Text('Voluntario')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro (especificar)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRank = val);
                  }
                },
              ),
              
              if (_selectedRank == 'Cadete') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCompany,
                  dropdownColor: AppColors.surface,
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Compañía',
                    prefixIcon: Icon(Icons.group_work_outlined,
                        color: AppColors.textMuted),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ICM', child: Text('I Compañía de Milicias (ICM)')),
                    DropdownMenuItem(value: 'IICM', child: Text('II Compañía de Milicias (IICM)')),
                    DropdownMenuItem(value: 'IIICM', child: Text('III Compañía de Milicias (IIICM)')),
                    DropdownMenuItem(value: 'IVCM', child: Text('IV Compañía de Milicias (IVCM)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCompany = val);
                    }
                  },
                ),
              ],
              
              if (_selectedRank == 'Otro') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customRankCtrl,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Especifique su cargo o función',
                    prefixIcon: Icon(Icons.edit_note_rounded,
                        color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Escriba su cargo o función' : null,
                ),
              ],
              const SizedBox(height: 16),

              // ── Número de Teléfono ─────────────────────────
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Número de teléfono',
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppColors.textMuted),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese su número telefónico' : null,
              ),
            ],

            // ── Error ──────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusDenied.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.statusDenied.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.statusDenied, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.statusDenied,
                        ))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Botón Login ────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isRegistering ? _signUp : _signIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isRegistering ? Icons.person_add_rounded : Icons.login_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(_isRegistering ? 'REGISTRARME E INGRESAR' : 'INGRESAR AL SISTEMA',
                              style: AppTextStyles.buttonPrimary),
                        ],
                      ),
              ),
            ),

            if (_isLoading && _loadingStatus != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _loadingStatus!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryLight,
                    letterSpacing: 1.5,
                  ),
                ),
              ).animate().fadeIn(duration: 150.ms),
            ],

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => setState(() {
                _isRegistering = !_isRegistering;
                _error = null;
              }),
              child: Text(
                _isRegistering
                    ? '¿YA TIENE CUENTA? INICIAR SESIÓN'
                    : '¿NO TIENE CUENTA? REGÍSTRESE AQUÍ (MODO PRUEBAS)',
                style: AppTextStyles.buttonSecondary.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Footer ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Acceso restringido a personal autorizado',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fondo de grid táctico ─────────────────────────────────
class _TacticalGridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceBorder.withOpacity(0.25)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
