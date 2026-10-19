import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ReadingRoomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? centerTitle;
  final Widget? trailing;
  final VoidCallback? onPracticeExamsTap;
  final VoidCallback? onMyResultsTap;
  final VoidCallback? onAdminTap;
  final bool showNav;
  final bool isPracticeActive;

  const ReadingRoomHeader({
    super.key,
    this.centerTitle,
    this.trailing,
    this.onPracticeExamsTap,
    this.onMyResultsTap,
    this.onAdminTap,
    this.showNav = true,
    this.isPracticeActive = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Reading Room',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'TOEIC READING EXAMS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center Title (if provided in workspace)
          if (centerTitle != null)
            Text(
              centerTitle!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

          // Trailing Actions
          if (trailing != null)
            trailing!
          else if (showNav)
            Row(
              children: [
                TextButton(
                  onPressed: onPracticeExamsTap,
                  child: Text(
                    'Practice exams',
                    style: TextStyle(
                      color: isPracticeActive ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isPracticeActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onMyResultsTap,
                  child: const Text(
                    'My results',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Admin Mode Button
                OutlinedButton.icon(
                  onPressed: onAdminTap,
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Chế độ Giáo viên (Admin)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderActive, width: 1.2),
                    backgroundColor: AppColors.surfaceSubtle,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 14),
                // Avatar Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'JK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Jamie Kim',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
