import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Экран входа: иконка в контейнере, заголовок, подзаголовок, форма (Фамилия, Имя, Отчество, Номер з/к), кнопка «Войти».
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _studentIdController = TextEditingController();

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final paddingH = width > 0 ? (AppUi.screenPaddingH * width / 448).clamp(16.0, 32.0) : AppUi.screenPaddingH;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(paddingH, 32, paddingH, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIconBox(),
              const SizedBox(height: AppUi.spacingXl),
              Center(
                child: Text(
                  'Вход в систему',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 32 / 24,
                    color: AppColors.loginPrimary,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Введите ваши данные для входа',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
              ),
              const SizedBox(height: AppUi.spacingXl),
              _buildForm(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox() {
    return Center(
      child: Container(
        width: AppUi.loginIconBoxSize,
        height: AppUi.loginIconBoxSize,
        decoration: BoxDecoration(
          color: AppColors.loginPrimary,
          borderRadius: BorderRadius.circular(AppUi.loginIconBoxRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.loginPrimary.withValues(alpha: 0.2),
              offset: const Offset(0, 8),
              blurRadius: 10,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: AppColors.loginPrimary.withValues(alpha: 0.2),
              offset: const Offset(0, 20),
              blurRadius: 25,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/teach.png',
            width: AppUi.loginIconSize,
            height: AppUi.loginIconSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.school, size: AppUi.loginIconSize, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(label: 'Фамилия', hint: 'Иванов', controller: _lastNameController),
          const SizedBox(height: 12),
          _buildField(label: 'Имя', hint: 'Иван', controller: _firstNameController),
          const SizedBox(height: 12),
          _buildField(label: 'Отчество', hint: 'Иванович', controller: _patronymicController),
          const SizedBox(height: 12),
          _buildField(label: 'Номер з/к', hint: '12345', controller: _studentIdController, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.name,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 15 / 10,
            letterSpacing: 1,
            color: AppColors.notificationSubtitle,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyle.inter(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.0,
              color: const Color(0x801E293B),
            ),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppUi.radiusM),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.0,
            color: const Color(0x801E293B),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Заполните поле';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _submit,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.loginPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUi.radiusL),
        ),
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 24 / 16,
        ),
      ),
      child: const Text('Войти'),
    );
  }
}
