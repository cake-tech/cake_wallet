import 'package:cake_wallet/src/screens/wallet_connect/utils/wc_permissions_mapper.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class WCPermissionsCard extends StatelessWidget {
  const WCPermissionsCard({super.key, required this.permissions});

  final List<WCPermission> permissions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (permissions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < permissions.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.outlineVariant, indent: 44),
            _PermissionRow(permission: permissions[i]),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.permission});

  final WCPermission permission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            child: CakeImageWidget(
              imageUrl: permission.iconUrl,
              width: 28,
              height: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permission.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
