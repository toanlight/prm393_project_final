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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await authProvider.signInWithEmailAndPassword(email, password);

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
                  Icons.account_balance_wallet_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceLg),
              const Text(
                'Giải pháp Quản lý Tài chính Thông minh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),
              Text(
                'Theo dõi thu chi, quản lý hóa đơn chứng từ và tự động hóa báo cáo tài chính cho doanh nghiệp.',
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
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 26,
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
                    'Đăng nhập Hệ thống',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceXs),
                  Text(
                    'Vui lòng nhập tài khoản do Quản trị viên (Admin) cấp',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceLg),

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
                        : const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceLg),

                  // Admin Notice Footer
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05) 
                          : AppDesignTokens.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppDesignTokens.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chưa có tài khoản? Vui lòng liên hệ Admin hệ thống để tạo mới.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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
