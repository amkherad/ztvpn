import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/proxy_models.dart';

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({
    super.key,
    required this.info,
    required this.onToggle,
  });

  final ConnectionInfo info;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(info.status);
    final statusLabel = _statusLabel(info.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (info.connectedSince != null)
                Text(
                  _formatDuration(DateTime.now().difference(info.connectedSince!)),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          if (info.localAddress != null) ...[
            const SizedBox(height: 10),
            Text(
              'Local: ${info.localAddress}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          if (info.activeProfile != null) ...[
            const SizedBox(height: 4),
            Text(
              info.activeProfile!.name,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          if (info.isConnected) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TrafficStat(
                    label: 'Upload',
                    value: _formatBytes(info.bytesSent),
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrafficStat(
                    label: 'Download',
                    value: _formatBytes(info.bytesReceived),
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
          ],
          if (info.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              info.errorMessage!,
              style: TextStyle(fontSize: 12, color: AppTheme.error),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: info.isBusy ? null : onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: info.isConnected ? AppTheme.error : AppTheme.accent,
              ),
              child: Text(info.isConnected ? 'Disconnect' : 'Connect'),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected => AppTheme.success,
      ConnectionStatus.connecting || ConnectionStatus.disconnecting =>
        AppTheme.warning,
      ConnectionStatus.error => AppTheme.error,
      ConnectionStatus.disconnected => AppTheme.textSecondary,
    };
  }

  String _statusLabel(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected => 'Connected',
      ConnectionStatus.connecting => 'Connecting...',
      ConnectionStatus.disconnecting => 'Disconnecting...',
      ConnectionStatus.error => 'Error',
      ConnectionStatus.disconnected => 'Disconnected',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _TrafficStat extends StatelessWidget {
  const _TrafficStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
