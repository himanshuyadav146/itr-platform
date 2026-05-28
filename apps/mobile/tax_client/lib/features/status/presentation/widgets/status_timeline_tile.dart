import 'package:flutter/material.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';

class StatusTimelineTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;
  final int index;
  final Animation<double> animation;
  final List<StatusUpdateModel>? statusUpdates;
  final AssignmentStatusModel? expertInfo;

  /// Called when user taps the action button on a pending update.
  /// Receives the message text so the caller can decide which page to open.
  final void Function(String message)? onActionTap;

  const StatusTimelineTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.isActive,
    required this.isLast,
    required this.index,
    required this.animation,
    this.statusUpdates,
    this.expertInfo,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Determine colors based on state
    final Color dotColor = isCompleted
        ? Colors.green
        : isActive
        ? scheme.primary
        : scheme.outlineVariant;

    final Color lineColor = isCompleted ? Colors.green : scheme.outlineVariant;

    final Color cardColor = isActive || isCompleted
        ? scheme.surface
        : scheme.surfaceContainerHighest.withOpacity(0.3);

    final Color textColor = isActive || isCompleted
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(0.5);

    final bool hasUpdates = statusUpdates != null && statusUpdates!.isNotEmpty;

    final bool hasExpert =
        expertInfo != null && expertInfo!.professionalName != null;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(animation),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Column
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: [
                          if (isActive || isCompleted)
                            BoxShadow(
                              color: dotColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? scheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      boxShadow: [
                        if (isActive || isCompleted)
                          BoxShadow(
                            color: scheme.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.2,
                          ),
                        ),

                        // ── Fallback subtitle (only when no updates and no expert) ──
                        if (!hasUpdates &&
                            !hasExpert &&
                            subtitle != null &&
                            (isActive || isCompleted)) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],

                        // ── Status Updates List ──────────────────────────
                        if (hasUpdates) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          ...statusUpdates!.map(
                            (update) => _StatusUpdateRow(
                              update: update,
                              theme: theme,
                              scheme: scheme,
                              onActionTap: onActionTap != null
                                  ? () => onActionTap!(update.message ?? '')
                                  : null,
                            ),
                          ),
                        ],

                        // ── Expert Info Card ─────────────────────────────
                        if (hasExpert) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          _ExpertInfoCard(
                            expert: expertInfo!,
                            theme: theme,
                            scheme: scheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual status update row widget
// ─────────────────────────────────────────────
class _StatusUpdateRow extends StatelessWidget {
  final StatusUpdateModel update;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback? onActionTap;

  const _StatusUpdateRow({
    required this.update,
    required this.theme,
    required this.scheme,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isResolved = update.status == 'resolved';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isResolved
              ? Colors.green.withOpacity(0.06)
              : Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isResolved
                ? Colors.green.withOpacity(0.25)
                : Colors.amber.withOpacity(0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status dot indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isResolved ? Colors.green : Colors.amber.shade700,
              ),
            ),
            const SizedBox(width: 10),
            // Message
            Expanded(
              child: Text(
                update.message ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ),
            // Only show action button for pending items
            if (!isResolved) ...[
              const SizedBox(width: 8),
              _ActionButton(onTap: onActionTap),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action button — only shown for pending updates
// ─────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ActionButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final amber = Colors.amber.shade700;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_rounded, size: 13, color: amber),
            const SizedBox(width: 4),
            Text(
              'Upload Now',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Expert info card — shown inside expert_assigned
// ─────────────────────────────────────────────
class _ExpertInfoCard extends StatelessWidget {
  final AssignmentStatusModel expert;
  final ThemeData theme;
  final ColorScheme scheme;

  const _ExpertInfoCard({
    required this.expert,
    required this.theme,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final name = expert.professionalName ?? 'Expert';
    final role = expert.professionalRole ?? '';
    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with initials
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primary.withOpacity(0.15),
                child: Text(
                  initials,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (role.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _RoleBadge(role: role, scheme: scheme),
                    ],
                  ],
                ),
              ),
              // Assigned indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Assigned',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Contact info
          if (expert.professionalEmail != null ||
              expert.professionalMobile != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (expert.professionalEmail != null)
              _ContactRow(
                icon: Icons.email_outlined,
                label: expert.professionalEmail!,
                scheme: scheme,
                theme: theme,
              ),
            if (expert.professionalMobile != null)
              _ContactRow(
                icon: Icons.phone_outlined,
                label: expert.professionalMobile!,
                scheme: scheme,
                theme: theme,
              ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final ColorScheme scheme;

  const _RoleBadge({required this.role, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final ThemeData theme;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
