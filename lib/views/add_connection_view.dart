import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/ssh_controller.dart';

/// 添加连接页面 - 针对 OPPO Pad 4 Pro 优化
class AddConnectionView extends StatefulWidget {
  const AddConnectionView({super.key});

  @override
  State<AddConnectionView> createState() => _AddConnectionViewState();
}

class _AddConnectionViewState extends State<AddConnectionView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _useKeyAuth = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加 SSH 连接'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveConnection,
            child: _isLoading
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildResponsiveLayout(),
      ),
    );
  }

  /// 构建响应式布局
  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // OPPO Pad 4 Pro 横屏模式：居中布局
        if (constraints.maxWidth > 600) {
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 500.w),
              child: _buildForm(),
            ),
          );
        }
        // 竖屏模式：全宽布局
        else {
          return _buildForm();
        }
      },
    );
  }

  /// 构建表单
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('基本信息'),
            SizedBox(height: 16.h),
            _buildNameField(),
            SizedBox(height: 16.h),
            _buildHostField(),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(flex: 2, child: _buildPortField()),
                SizedBox(width: 16.w),
                Expanded(flex: 3, child: _buildUsernameField()),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle('认证方式'),
            SizedBox(height: 16.h),
            _buildAuthMethodTabs(),
            SizedBox(height: 16.h),
            _useKeyAuth ? _buildPrivateKeyField() : _buildPasswordField(),
            SizedBox(height: 24.h),
            _buildSectionTitle('其他信息'),
            SizedBox(height: 16.h),
            _buildDescriptionField(),
            SizedBox(height: 32.h),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// 构建连接名称字段
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: '连接名称',
        hintText: '例如：生产服务器',
        prefixIcon: const Icon(Icons.label_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      validator: (value) {
        if (value?.trim().isEmpty == true) {
          return '请输入连接名称';
        }
        return null;
      },
    );
  }

  /// 构建主机地址字段
  Widget _buildHostField() {
    return TextFormField(
      controller: _hostController,
      decoration: InputDecoration(
        labelText: '主机地址',
        hintText: '例如：192.168.1.100 或 example.com',
        prefixIcon: const Icon(Icons.dns_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      validator: (value) {
        if (value?.trim().isEmpty == true) {
          return '请输入主机地址';
        }
        return null;
      },
    );
  }

  /// 构建端口字段
  Widget _buildPortField() {
    return TextFormField(
      controller: _portController,
      decoration: InputDecoration(
        labelText: '端口',
        prefixIcon: const Icon(Icons.settings_ethernet),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.trim().isEmpty == true) {
          return '请输入端口';
        }
        final port = int.tryParse(value!);
        if (port == null || port < 1 || port > 65535) {
          return '端口范围：1-65535';
        }
        return null;
      },
    );
  }

  /// 构建用户名字段
  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: '用户名',
        hintText: '例如：root, admin',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      validator: (value) {
        if (value?.trim().isEmpty == true) {
          return '请输入用户名';
        }
        return null;
      },
    );
  }

  /// 构建认证方式选择
  Widget _buildAuthMethodTabs() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildAuthTab('密码认证', Icons.lock_outline, !_useKeyAuth, () {
              setState(() {
                _useKeyAuth = false;
              });
            }),
          ),
          Expanded(
            child: _buildAuthTab('密钥认证', Icons.key_outlined, _useKeyAuth, () {
              setState(() {
                _useKeyAuth = true;
              });
            }),
          ),
        ],
      ),
    );
  }

  /// 构建认证方式标签
  Widget _buildAuthTab(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建密码字段
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '输入登录密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      validator: (value) {
        if (!_useKeyAuth && value?.trim().isEmpty == true) {
          return '请输入密码';
        }
        return null;
      },
    );
  }

  /// 构建私钥字段
  Widget _buildPrivateKeyField() {
    return TextFormField(
      controller: _privateKeyController,
      maxLines: 8,
      decoration: InputDecoration(
        labelText: '私钥内容',
        hintText: '粘贴 SSH 私钥内容...',
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      validator: (value) {
        if (_useKeyAuth && value?.trim().isEmpty == true) {
          return '请输入私钥内容';
        }
        return null;
      },
    );
  }

  /// 构建描述字段
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '描述（可选）',
        hintText: '添加连接的描述信息...',
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.description_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveConnection,
        icon: _isLoading
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? '保存中...' : '保存连接'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  /// 保存连接
  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<SshController>().addConnection(
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _useKeyAuth ? null : _passwordController.text.trim(),
        privateKey: _useKeyAuth ? _privateKeyController.text.trim() : null,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('连接已保存')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请重试')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}