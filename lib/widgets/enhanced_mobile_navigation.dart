import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/enhanced_responsive_helper.dart';
import '../theme/app_theme.dart';

class EnhancedMobileNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<EnhancedNavItem> items;
  final bool enableHapticFeedback;
  
  const EnhancedMobileNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!EnhancedResponsiveHelper.isMobile(context)) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: EnhancedResponsiveHelper.getBottomNavigationHeight(context),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;
            
            return Expanded(
              child: _buildNavItem(
                context,
                item,
                isSelected,
                () => _handleTap(context, index),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(
    BuildContext context,
    EnhancedNavItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = isSelected 
        ? (item.activeColor ?? AppTheme.primaryColor)
        : (item.inactiveColor ?? Colors.grey);
    
    final iconSize = EnhancedResponsiveHelper.getEnhancedResponsiveValue(
      context,
      smallMobile: 22.0,
      mobile: 24.0,
      largeMobile: 26.0,
    );
    
    final fontSize = EnhancedResponsiveHelper.getEnhancedFontSize(
      context,
      baseFontSize: 10.0,
    );
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: EnhancedResponsiveHelper.getEnhancedResponsiveValue(
            context,
            smallMobile: 6.0,
            mobile: 8.0,
            largeMobile: 10.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge wrapper for icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 8 : 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? color.withAlpha(25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: iconSize,
                    color: color,
                  ),
                ),
                // Badge
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: item.badgeColor ?? Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize * 0.8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleTap(BuildContext context, int index) {
    if (enableHapticFeedback) {
      EnhancedResponsiveHelper.provideSelectionFeedback(context);
    }
    onTap(index);
  }
}

class EnhancedNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color? activeColor;
  final Color? inactiveColor;
  final int? badgeCount;
  final Color? badgeColor;
  
  const EnhancedNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.activeColor,
    this.inactiveColor,
    this.badgeCount,
    this.badgeColor,
  });
}

// Enhanced App Bar for mobile
class EnhancedMobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool enableBackButton;
  final VoidCallback? onBackPressed;
  
  const EnhancedMobileAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.enableBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appBarHeight = EnhancedResponsiveHelper.getEnhancedAppBarHeight(context);
    final titleFontSize = EnhancedResponsiveHelper.getEnhancedFontSize(
      context,
      baseFontSize: 18.0,
    );
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation ?? 2,
      leading: leading ?? (enableBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (EnhancedResponsiveHelper.isMobile(context)) {
                  EnhancedResponsiveHelper.provideTouchFeedback(context);
                }
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  Navigator.pop(context);
                }
              },
            )
          : null),
      actions: actions?.map((action) {
        if (action is IconButton) {
          return IconButton(
            icon: action.icon,
            onPressed: () {
              if (EnhancedResponsiveHelper.isMobile(context)) {
                EnhancedResponsiveHelper.provideTouchFeedback(context);
              }
              action.onPressed?.call();
            },
            tooltip: action.tooltip,
          );
        }
        return action;
      }).toList(),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Enhanced Drawer for mobile navigation
class EnhancedMobileDrawer extends StatelessWidget {
  final String? userDisplayName;
  final String? userEmail;
  final String? userAvatarUrl;
  final List<EnhancedDrawerItem> items;
  final Function(String)? onItemTap;
  final Widget? header;
  final Widget? footer;
  
  const EnhancedMobileDrawer({
    super.key,
    this.userDisplayName,
    this.userEmail,
    this.userAvatarUrl,
    required this.items,
    this.onItemTap,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final drawerWidth = EnhancedResponsiveHelper.getNavigationDrawerWidth(context);
    
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: Column(
          children: [
            // Header
            header ?? _buildDefaultHeader(context),
            
            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items.map((item) => _buildDrawerItem(context, item)).toList(),
              ),
            ),
            
            // Footer
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      accountName: Text(userDisplayName ?? 'Student'),
      accountEmail: Text(userEmail ?? 'student@school.edu'),
      currentAccountPicture: CircleAvatar(
        backgroundImage: userAvatarUrl != null 
            ? NetworkImage(userAvatarUrl!)
            : null,
        child: userAvatarUrl == null 
            ? const Icon(Icons.person, size: 40)
            : null,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildDrawerItem(BuildContext context, EnhancedDrawerItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.color ?? AppTheme.primaryColor,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: EnhancedResponsiveHelper.getEnhancedFontSize(
            context,
            baseFontSize: 16.0,
          ),
        ),
      ),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.trailing,
      onTap: () {
        if (EnhancedResponsiveHelper.isMobile(context)) {
          EnhancedResponsiveHelper.provideTouchFeedback(context);
        }
        Navigator.pop(context); // Close drawer
        onItemTap?.call(item.route);
      },
    );
  }
}

class EnhancedDrawerItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;
  final Color? color;
  final Widget? trailing;
  
  const EnhancedDrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    this.subtitle,
    this.color,
    this.trailing,
  });
}

// Floating Action Button with enhanced mobile features
class EnhancedMobileFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enableHapticFeedback;
  final String? heroTag;
  
  const EnhancedMobileFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.enableHapticFeedback = true,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (!EnhancedResponsiveHelper.isMobile(context)) {
      return const SizedBox.shrink();
    }
    
    final fabSize = EnhancedResponsiveHelper.getEnhancedResponsiveValue(
      context,
      smallMobile: 56.0,
      mobile: 56.0,
      largeMobile: 60.0,
    );
    
    final iconSize = EnhancedResponsiveHelper.getEnhancedResponsiveValue(
      context,
      smallMobile: 24.0,
      mobile: 24.0,
      largeMobile: 28.0,
    );
    
    return SizedBox(
      width: fabSize,
      height: fabSize,
      child: FloatingActionButton(
        onPressed: () {
          if (enableHapticFeedback) {
            EnhancedResponsiveHelper.provideTouchFeedback(context);
          }
          onPressed();
        },
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        tooltip: tooltip,
        heroTag: heroTag,
        child: Icon(icon, size: iconSize),
      ),
    );
  }
}
