import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_isSignUp) {
      await authProvider.signUpWithEmailAndPassword(email, password, name);
    } else {
      await authProvider.signInWithEmailAndPassword(email, password);
    }

    if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppDesignTokens.error,
        ),
      );
      authProvider.clearError();
    }
  }

  Future<void> _loginAnonymously() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInAnonymously();
    if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppDesignTokens.error,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Left side panel on large screens
    Widget buildLeftPanel() {
      return Container(
        decoration: const BoxDecoration(
          gradient: AppDesignTokens.primaryGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.space2Xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceLg),
              const Text(
                'Nền tảng khởi tạo tối ưu cho Flutter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),
              Text(
                'Kiến trúc phân lớp chuẩn mực Clean Architecture, tích hợp Firebase linh hoạt và phản hồi nhanh chóng trên mọi thiết bị.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Right side (or main) login card
    Widget buildLoginForm() {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsiveValue(
            mobile: AppDesignTokens.spaceLg,
            tablet: AppDesignTokens.spaceXl,
            desktop: AppDesignTokens.space2Xl,
          )),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
            decoration: BoxDecoration(
              color: isDark ? AppDesignTokens.glassBgDark : AppDesignTokens.glassBgLight,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
              border: Border.all(
                color: isDark ? AppDesignTokens.glassBorderDark : AppDesignTokens.glassBorderLight,
                width: 1.5,
              ),
              boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDesignTokens.spaceXs),
                        decoration: BoxDecoration(
                          gradient: AppDesignTokens.primaryGradient,
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.spaceSm),
                      Text(
                        'SMART FINANCE',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spaceLg),
                  
                  Text(
                    _isSignUp ? 'Đăng ký tài khoản' : 'Chào mừng trở lại!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceXs),
                  Text(
                    _isSignUp
                        ? 'Tạo tài khoản để trải nghiệm dịch vụ'
                        : 'Vui lòng đăng nhập để tiếp tục sử dụng',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spaceLg),

                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên hiển thị';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spaceMd),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spaceMd),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải từ 6 ký tự trở lên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDesignTokens.spaceLg),

                  // Submit Button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_isSignUp ? 'Đăng ký' : 'Đăng nhập'),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceMd),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.spaceSm),
                        child: Text(
                          'Hoặc',
                          style: TextStyle(
                            color: Theme.of(context).hintColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spaceMd),

                  // Demo Login (Anonymous)
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading ? null : _loginAnonymously,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      side: BorderSide(
                        color: AppDesignTokens.primary.withOpacity(0.4),
                      ),
                    ),
                    icon: const Icon(Icons.person_pin_outlined),
                    label: const Text('Đăng nhập Ẩn danh (Demo)'),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceLg),

                  // Toggle Login / Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                        child: Text(
                          _isSignUp ? 'Đăng nhập' : 'Đăng ký ngay',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppResponsiveLayout(
        mobile: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppDesignTokens.darkBackgroundGradient
                : const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
          ),
          child: buildLoginForm(),
        ),
        desktop: Row(
          children: [
            Expanded(flex: 5, child: buildLeftPanel()),
            Expanded(
              flex: 6,
              child: Container(
                color: isDark ? AppDesignTokens.darkBackground : AppDesignTokens.lightBackground,
                child: buildLoginForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
