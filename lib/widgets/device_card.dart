import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/device.dart';
import '../theme/app_colors.dart';

/// Device card
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Device image
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: device.online ? AppColors.subtle : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: device.imageUrl != null && device.imageUrl!.isNotEmpty
                  ? Image.network(device.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _a) => Icon(Icons.speaker, size: 22,
                          color: device.online ? AppColors.primary : AppColors.offline))
                  : Icon(Icons.speaker, size: 22,
                      color: device.online ? AppColors.primary : AppColors.offline),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: device.online ? AppColors.online : AppColors.offline)),
                  const SizedBox(width: 5),
                  Text(device.online ? l.online : l.offline,
                      style: TextStyle(fontSize: 12,
                          color: device.online ? AppColors.online : Colors.grey[400])),
                ]),
              ],
            )),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
          ]),
        ),
      ),
    );
  }
}
