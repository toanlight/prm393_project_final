import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/models/user_model.dart';
import '../providers/user_management_provider.dart';
import '../providers/auth_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().fetchUsers();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Role Metadata for Vietnamese localization and Theme color
  Map<String, _RoleMeta> get _roleMetas => {
    'admin': const _RoleMeta(
      name: 'Admin Hệ thống',
      color: AppDesignTokens.error,
      icon: Icons.admin_panel_settings_rounded,
    ),
    'chiefAccountant': const _RoleMeta(
      name: 'Kế toán trưởng',
      color: Colors.purple,
      icon: Icons.supervisor_account_rounded,
    ),
    'accountant': const _RoleMeta(
      name: 'Kế toán viên',
      color: AppDesignTokens.info,
      icon: Icons.account_balance_wallet_rounded,
    ),
    'salesperson': const _RoleMeta(
      name: 'Nhân viên Bán hàng',
      color: AppDesignTokens.warning,
      icon: Icons.point_of_sale_rounded,
    ),
    'manager': const _RoleMeta(
      name: 'Quản lý',
      color: AppDesignTokens.secondary,
      icon: Icons.manage_accounts_rounded,
    ),
    'partner': const _RoleMeta(
      name: 'Đối tác Doanh nghiệp',
      color: AppDesignTokens.success,
      icon: Icons.business_rounded,
    ),
    'viewer': const _RoleMeta(
      name: 'Viewer / Khách',
      color: Colors.grey,
      icon: Icons.visibility_rounded,
    ),
  };

  _RoleMeta _getRoleMeta(String roleId) {
    return _roleMetas[roleId] ?? const _RoleMeta(
      name: 'Người dùng',
      color: Colors.blueGrey,
      icon: Icons.person_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();
    final currentAdmin = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtered users
    final filteredUsers = provider.users.where((user) {
      final matchesSearch = user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRoleFilter == null || user.roleId == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchUsers(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              mobile: AppDesignTokens.spaceMd,
              tablet: AppDesignTokens.spaceLg,
              desktop: AppDesignTokens.spaceXl,
            ),
            vertical: AppDesignTokens.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter Card
              Card(
                elevation: 0,
                color: isDark ? AppDesignTokens.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                  side: BorderSide(
                    color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên hoặc email...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppDesignTokens.spaceSm,
                            horizontal: AppDesignTokens.spaceMd,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spaceMd),
                      
                      // Role filter list
                      LayoutBuilder(
                        builder: (context, filterConstraints) {
                          final chips = [
                            ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: _selectedRoleFilter == null,
                              onSelected: (_) => setState(() => _selectedRoleFilter = null),
                            ),
                            ..._roleMetas.entries.map((entry) {
                              final meta = entry.value;
                              return ChoiceChip(
                                label: Text(meta.name),
                                selected: _selectedRoleFilter == entry.key,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedRoleFilter = selected ? entry.key : null;
                                  });
                                },
                              );
                            }),
                          ];

                          if (filterConstraints.maxWidth > 500) {
                            return Wrap(
                              spacing: AppDesignTokens.spaceXs,
                              runSpacing: AppDesignTokens.spaceXs,
                              children: chips,
                            );
                          } else {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: chips
                                    .map((chip) => Padding(
                                          padding: const EdgeInsets.only(right: AppDesignTokens.spaceXs),
                                          child: chip,
                                        ))
                                    .toList(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),

              // Users Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.spaceXs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kết quả: ${filteredUsers.length} người dùng',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceSm),

              // User List View
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: AppDesignTokens.error),
                                const SizedBox(height: AppDesignTokens.spaceSm),
                                Text(
                                  'Đã xảy ra lỗi:\n${provider.errorMessage}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppDesignTokens.error),
                                ),
                                const SizedBox(height: AppDesignTokens.spaceMd),
                                ElevatedButton(
                                  onPressed: () => provider.fetchUsers(),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : filteredUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline_rounded,
                                      size: 64,
                                      color: isDark ? Colors.grey[700] : Colors.grey[400],
                                    ),
                                    const SizedBox(height: AppDesignTokens.spaceMd),
                                    Text(
                                      'Không tìm thấy người dùng nào.',
                                      style: TextStyle(
                                        color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, listConstraints) {
                                  final double width = listConstraints.maxWidth;
                                  final int crossAxisCount = width > 600 ? 2 : 1;

                                  if (crossAxisCount > 1) {
                                    return GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: AppDesignTokens.spaceMd,
                                        mainAxisSpacing: AppDesignTokens.spaceSm,
                                        mainAxisExtent: 116,
                                      ),
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final isSelf = user.uid == currentAdmin?.uid;
                                        final roleMeta = _getRoleMeta(user.roleId);
                                        return _buildUserCard(user, isSelf, roleMeta, isDark);
                                      },
                                    );
                                  } else {
                                    return ListView.builder(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final isSelf = user.uid == currentAdmin?.uid;
                                        final roleMeta = _getRoleMeta(user.roleId);
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: AppDesignTokens.spaceSm),
                                          child: _buildUserCard(user, isSelf, roleMeta, isDark),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    UserModel user,
    bool isSelf,
    _RoleMeta roleMeta,
    bool isDark,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? AppDesignTokens.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        side: BorderSide(
          color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spaceMd,
          vertical: AppDesignTokens.spaceXs,
        ),
        leading: Hero(
          tag: 'avatar_${user.uid}',
          child: CircleAvatar(
            radius: 22,
            backgroundColor: roleMeta.color.withOpacity(0.1),
            backgroundImage: user.photoUrl.isNotEmpty
                ? NetworkImage(user.photoUrl)
                : null,
            child: user.photoUrl.isEmpty
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: roleMeta.color,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppDesignTokens.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusXs),
                ),
                child: const Text(
                  'BẠN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppDesignTokens.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppDesignTokens.darkTextSecondary
                    : AppDesignTokens.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleMeta.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                    border: Border.all(
                      color: roleMeta.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleMeta.icon, size: 12, color: roleMeta.color),
                      const SizedBox(width: 4),
                      Text(
                        roleMeta.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: roleMeta.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (user.isActive
                            ? AppDesignTokens.success
                            : AppDesignTokens.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user.isActive
                              ? AppDesignTokens.success
                              : AppDesignTokens.error,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isActive ? 'Đang hoạt động' : 'Đã khóa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.isActive
                              ? AppDesignTokens.success
                              : AppDesignTokens.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => _showEditUserBottomSheet(user, isSelf),
        ),
      ),
    );
  }

  void _showEditUserBottomSheet(UserModel user, bool isSelf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Form variables
    String selectedRole = user.roleId;
    bool activeStatus = user.isActive;
    final nameController = TextEditingController(text: user.fullName);
    final taxCodeController = TextEditingController(text: user.taxCode ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isPartner = selectedRole == 'partner';
            
            return Container(
              margin: const EdgeInsets.all(AppDesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppDesignTokens.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
                border: Border.all(
                  color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppDesignTokens.spaceLg,
                  right: AppDesignTokens.spaceLg,
                  top: AppDesignTokens.spaceLg,
                  bottom: MediaQuery.of(context).viewInsets.bottom + AppDesignTokens.spaceLg,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chỉnh sửa người dùng',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignTokens.spaceMd),
                      
                      // Account Info Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                            child: user.photoUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                          ),
                          const SizedBox(width: AppDesignTokens.spaceSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.email,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'UID: ${user.uid}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignTokens.spaceLg),

                      // Form Fields
                      const Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppDesignTokens.spaceXs),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập họ và tên...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spaceMd),

                      // Role Select Dropdown
                      const Text('Vai trò hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppDesignTokens.spaceXs),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          enabled: !isSelf, // Can't change own role
                          helperText: isSelf ? 'Bạn không thể thay đổi vai trò của chính mình.' : null,
                        ),
                        items: _roleMetas.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Icon(entry.value.icon, size: 18, color: entry.value.color),
                                const SizedBox(width: 8),
                                Text(entry.value.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: isSelf
                            ? null
                            : (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedRole = val;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: AppDesignTokens.spaceMd),

                      // Tax code field (partner only)
                      if (isPartner) ...[
                        const Text('Mã số thuế doanh nghiệp', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppDesignTokens.spaceXs),
                        TextField(
                          controller: taxCodeController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã số thuế (bắt buộc cho Đối tác)...',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppDesignTokens.spaceMd),
                      ],

                      // Active Switch
                      SwitchListTile(
                        title: const Text('Trạng thái hoạt động'),
                        subtitle: const Text('Tắt để khóa tài khoản, chặn đăng nhập vào hệ thống'),
                        value: activeStatus,
                        activeColor: AppDesignTokens.success,
                        contentPadding: EdgeInsets.zero,
                        onChanged: isSelf
                            ? null // Can't deactivate self
                            : (val) {
                                setModalState(() {
                                  activeStatus = val;
                                });
                              },
                      ),
                      if (isSelf)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Bạn không thể vô hiệu hóa tài khoản của chính mình.',
                            style: TextStyle(fontSize: 12, color: AppDesignTokens.warning),
                          ),
                        ),
                      const SizedBox(height: AppDesignTokens.spaceLg),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(bottomSheetCtx),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: AppDesignTokens.spaceMd),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppDesignTokens.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final fullName = nameController.text.trim();
                                if (fullName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Họ và tên không được bỏ trống!'),
                                      backgroundColor: AppDesignTokens.error,
                                    ),
                                  );
                                  return;
                                }

                                if (selectedRole == 'partner' && taxCodeController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng nhập Mã số thuế cho Đối tác!'),
                                      backgroundColor: AppDesignTokens.error,
                                    ),
                                  );
                                  return;
                                }

                                final updatedUser = user.copyWith(
                                  fullName: fullName,
                                  roleId: selectedRole,
                                  isActive: activeStatus,
                                  taxCode: selectedRole == 'partner'
                                      ? taxCodeController.text.trim()
                                      : null,
                                );

                                Navigator.pop(bottomSheetCtx);

                                // Perform save
                                final currentAdminUid = context.read<AuthProvider>().user?.uid ?? '';
                                final success = await context
                                    .read<UserManagementProvider>()
                                    .updateUser(updatedUser, currentAdminUid);

                                if (success) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã cập nhật thông tin người dùng thành công!'),
                                        backgroundColor: AppDesignTokens.success,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (errCtx) => AlertDialog(
                                        title: const Text('Lỗi cập nhật'),
                                        content: Text(
                                          'Không thể cập nhật thông tin:\n${context.read<UserManagementProvider>().errorMessage}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(errCtx),
                                            child: const Text('Đóng'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Lưu thay đổi'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoleMeta {
  final String name;
  final Color color;
  final IconData icon;

  const _RoleMeta({
    required this.name,
    required this.color,
    required this.icon,
  });
}
