import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../controllers/ssh_controller.dart';
import '../models/ssh_connection.dart';

/// 添加连接页面 - 针对 OPPO Pad 4 Pro 优化
class AddConnectionView extends StatefulWidget {
  final SshConnection? connection; // 如果为null则为新增模式，不为null则为编辑模式
  
  const AddConnectionView({super.key, this.connection});

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
  bool _useKeyFile = false; // true: 文件选择, false: 文本输入
  String? _selectedKeyFileName;

  // 判断是否为编辑模式
  bool get _isEditMode => widget.connection != null;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  /// 初始化表单数据（编辑模式时填充现有数据）
  void _initializeFormData() {
    final connection = widget.connection;
    if (connection != null) {
      _nameController.text = connection.name;
      _hostController.text = connection.host;
      _portController.text = connection.port.toString();
      _usernameController.text = connection.username;
      _descriptionController.text = connection.description ?? '';
      
      // 设置认证方式
      _useKeyAuth = connection.useKeyAuth;
      if (_useKeyAuth && connection.privateKey != null) {
        _privateKeyController.text = connection.privateKey!;
      } else if (!_useKeyAuth && connection.password != null) {
        _passwordController.text = connection.password!;
      }
    }
  }

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
        title: Text(_isEditMode ? '编辑 SSH 连接' : '添加 SSH 连接'),
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
        fontSize: 27.sp,
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
                fontSize: 18.sp,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 输入方式选择
        Row(
          children: [
            Expanded(
              child: _buildKeyInputTab('文本输入', Icons.edit_outlined, !_useKeyFile, () {
                setState(() {
                  _useKeyFile = false;
                  _selectedKeyFileName = null;
                });
              }),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildKeyInputTab('选择文件', Icons.file_open_outlined, _useKeyFile, () {
                setState(() {
                  _useKeyFile = true;
                });
              }),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        
        // 根据选择显示不同的输入方式
        if (_useKeyFile) ...[
          _buildKeyFileSelector(),
        ] else ...[
          _buildKeyTextInput(),
        ],
      ],
    );
  }

  /// 构建密钥输入方式标签
  Widget _buildKeyInputTab(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 4.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建密钥文件选择器
  Widget _buildKeyFileSelector() {
    return Column(
      children: [
        InkWell(
          onTap: _pickKeyFile,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedKeyFileName != null ? Icons.file_present : Icons.file_upload_outlined,
                  size: 48.sp,
                  color: _selectedKeyFileName != null 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 8.h),
                Text(
                  _selectedKeyFileName ?? '点击选择密钥文件',
                  style: TextStyle(
                    fontSize: 21.sp,
                    color: _selectedKeyFileName != null 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: _selectedKeyFileName != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '支持格式：.pem, .key, .ppk, .rsa, .ed25519',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedKeyFileName != null) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '已选择: $_selectedKeyFileName',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedKeyFileName = null;
                    _privateKeyController.clear();
                  });
                },
                child: const Text('清除'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 构建密钥文本输入
  Widget _buildKeyTextInput() {
    return TextFormField(
      controller: _privateKeyController,
      maxLines: 8,
      decoration: InputDecoration(
        labelText: '私钥内容',
        hintText: '粘贴 SSH 私钥内容...\n例如：\n-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----',
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      validator: (value) {
        if (_useKeyAuth && !_useKeyFile && value?.trim().isEmpty == true) {
          return '请输入私钥内容';
        }
        if (_useKeyAuth && _useKeyFile && _selectedKeyFileName == null) {
          return '请选择私钥文件';
        }
        return null;
      },
    );
  }

  /// 选择密钥文件
  Future<void> _pickKeyFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'key', 'ppk', 'rsa', 'ed25519', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        // 读取文件内容
        try {
          final keyContent = await file.readAsString();
          
          // 验证文件内容是否像密钥文件
          if (_isValidKeyFormat(keyContent)) {
            setState(() {
              _selectedKeyFileName = fileName;
              _privateKeyController.text = keyContent;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('成功加载密钥文件: $fileName')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件格式不正确，请选择有效的SSH密钥文件')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('读取文件失败: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  /// 验证密钥格式
  bool _isValidKeyFormat(String content) {
    final trimmed = content.trim();
    
    // 检查常见的密钥格式开头
    final validHeaders = [
      '-----BEGIN OPENSSH PRIVATE KEY-----',
      '-----BEGIN RSA PRIVATE KEY-----',
      '-----BEGIN DSA PRIVATE KEY-----',
      '-----BEGIN EC PRIVATE KEY-----',
      '-----BEGIN PRIVATE KEY-----',
      'PuTTY-User-Key-File-',  // PuTTY format
    ];
    
    return validHeaders.any((header) => trimmed.startsWith(header)) ||
           (trimmed.length > 50 && trimmed.contains('PRIVATE KEY'));
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
        label: Text(_isLoading ? '保存中...' : (_isEditMode ? '更新连接' : '保存连接')),
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
      final controller = context.read<SshController>();
      final bool success;
      
      if (_isEditMode) {
        // 编辑模式 - 更新现有连接
        final updatedConnection = widget.connection!.copyWith(
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
        success = await controller.updateConnection(updatedConnection);
      } else {
        // 新增模式 - 创建新连接
        success = await controller.addConnection(
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
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditMode ? '连接已更新' : '连接已保存')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditMode ? '更新失败，请重试' : '保存失败，请重试')),
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