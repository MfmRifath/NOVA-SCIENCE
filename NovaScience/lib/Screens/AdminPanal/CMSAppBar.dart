import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import the design system
import 'CMSDesignSystem.dart';

/// A consistent app bar with optional search and filter functionality
class CMSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final TabBar? bottom;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CMSAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.bottom,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: CMSDesignSystem.primaryGreen,
      leading: showBackButton
          ? IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + 48);
}

/// A search bar component with consistent styling
class CMSSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const CMSSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.hintText = 'Search...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(CMSDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: CMSDesignSystem.white,
        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusLarge),
        boxShadow: CMSDesignSystem.shadowLow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: CMSDesignSystem.primaryBlue,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: CMSDesignSystem.primaryBlue,
            ),
            onPressed: () {
              controller.clear();
              onChanged('');
              if (onClear != null) onClear!();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: CMSDesignSystem.spacing12,
            horizontal: CMSDesignSystem.spacing16,
          ),
        ),
      ),
    );
  }
}

/// A course card with consistent styling
class CMSCourseCard extends StatelessWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final String? instructor;
  final String? description;
  final String? status;
  final String? medium;
  final double? price;
  final bool isApproved;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CMSCourseCard({
    Key? key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.instructor,
    this.description,
    this.status,
    this.medium,
    this.price,
    this.isApproved = true,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color _getStatusColor() {
    if (status == 'free') {
      return CMSDesignSystem.freeCourseColor;
    } else if (status == 'Premium') {
      return CMSDesignSystem.premiumCourseColor;
    } else {
      return CMSDesignSystem.pendingCourseColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: EdgeInsets.symmetric(vertical: CMSDesignSystem.spacing8, horizontal: CMSDesignSystem.spacing16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusLarge),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusLarge),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar at top
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(CMSDesignSystem.radiusLarge),
                  topRight: Radius.circular(CMSDesignSystem.radiusLarge),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(CMSDesignSystem.spacing16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 120,
                        color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CMSDesignSystem.primaryBlue,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: CMSDesignSystem.primaryBlue,
                        ),
                      ),
                    )
                        : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: CMSDesignSystem.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: CMSDesignSystem.spacing16),
                  // Course Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge Row
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: CMSDesignSystem.spacing8, vertical: CMSDesignSystem.spacing4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusSmall),
                              ),
                              child: Text(
                                status != null
                                    ? '${status![0].toUpperCase()}${status!.substring(1)}'
                                    : 'N/A',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (medium != null) ...[
                              SizedBox(width: CMSDesignSystem.spacing8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: CMSDesignSystem.spacing8, vertical: CMSDesignSystem.spacing4),
                                decoration: BoxDecoration(
                                  color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(CMSDesignSystem.radiusSmall),
                                ),
                                child: Text(
                                  medium!,
                                  style: TextStyle(
                                    color: CMSDesignSystem.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (!isApproved) ...[
                              SizedBox(width: CMSDesignSystem.spacing8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: CMSDesignSystem.spacing8, vertical: CMSDesignSystem.spacing4),
                                decoration: BoxDecoration(
                                  color: CMSDesignSystem.accentMaroon.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(CMSDesignSystem.radiusSmall),
                                ),
                                child: Text(
                                  'Under Review',
                                  style: TextStyle(
                                    color: CMSDesignSystem.accentMaroon,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: CMSDesignSystem.spacing8),
                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CMSDesignSystem.textPrimary,
                          ),
                        ),
                        SizedBox(height: CMSDesignSystem.spacing4),
                        // Instructor
                        if (instructor != null && instructor!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: CMSDesignSystem.primaryBlue,
                              ),
                              SizedBox(width: CMSDesignSystem.spacing4),
                              Text(
                                instructor!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CMSDesignSystem.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: CMSDesignSystem.spacing8),
                        // Description
                        Text(
                          description ?? 'No Description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: CMSDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                CMSDesignSystem.spacing16,
                0,
                CMSDesignSystem.spacing16,
                CMSDesignSystem.spacing16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price
                  Row(
                    children: [
                      Icon(
                        price != null && price! > 0
                            ? Icons.attach_money_rounded
                            : Icons.money_off_rounded,
                        size: 18,
                        color: price != null && price! > 0
                            ? CMSDesignSystem.primaryBlue
                            : CMSDesignSystem.freeCourseColor,
                      ),
                      SizedBox(width: CMSDesignSystem.spacing4),
                      Text(
                        price != null && price! > 0
                            ? '${price}'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: price != null && price! > 0
                              ? CMSDesignSystem.primaryBlue
                              : CMSDesignSystem.freeCourseColor,
                        ),
                      ),
                    ],
                  ),
                  // Actions
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          color: CMSDesignSystem.primaryBlue,
                        ),
                        tooltip: 'Edit Course',
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: CMSDesignSystem.accentMaroon,
                        ),
                        tooltip: 'Delete Course',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom tab indicator for the tab bar
class CMSTabIndicator extends Decoration {
  final Color color;
  final double radius;
  final double height;

  const CMSTabIndicator({
    this.color = Colors.white,
    this.radius = 8.0,
    this.height = 4.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CMSTabPainter(
      color: color,
      radius: radius,
      height: height,
    );
  }
}

class _CMSTabPainter extends BoxPainter {
  final Color color;
  final double radius;
  final double height;

  _CMSTabPainter({
    required this.color,
    required this.radius,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double indicatorWidth = rect.width * 0.6;
    final double horizontalCenter = rect.left + rect.width / 2;
    final double bottom = rect.bottom - 2.0;

    final RRect indicatorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        horizontalCenter - indicatorWidth / 2,
        bottom - height,
        indicatorWidth,
        height,
      ),
      Radius.circular(radius),
    );

    canvas.drawRRect(indicatorRect, paint);
  }
}

/// A custom floating action button with a gradient
class CMSFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color startColor;
  final Color endColor;

  const CMSFloatingActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.startColor = const Color(0xFF123755),
    this.endColor = const Color(0xFF1D517D),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusCircular),
        boxShadow: CMSDesignSystem.shadowMedium,
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }
}

/// A custom empty state widget
class CMSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? actionButton;

  const CMSEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(CMSDesignSystem.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: CMSDesignSystem.primaryBlue.withOpacity(0.5),
            ),
            SizedBox(height: CMSDesignSystem.spacing16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CMSDesignSystem.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: CMSDesignSystem.spacing8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: CMSDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              SizedBox(height: CMSDesignSystem.spacing24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A custom error state widget
class CMSErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CMSErrorState({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(CMSDesignSystem.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: CMSDesignSystem.error,
            ),
            SizedBox(height: CMSDesignSystem.spacing16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CMSDesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: CMSDesignSystem.spacing8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: CMSDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: CMSDesignSystem.spacing24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom loading state widget
class CMSLoadingState extends StatelessWidget {
  final String message;

  const CMSLoadingState({
    Key? key,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
          ),
          SizedBox(height: CMSDesignSystem.spacing16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: CMSDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom confirmation dialog
class CMSConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Color confirmColor;
  final IconData? icon;

  const CMSConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    required this.onCancel,
    required this.onConfirm,
    this.confirmColor = const Color(0xFF123755),
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: confirmColor,
              size: 24,
            ),
            SizedBox(width: CMSDesignSystem.spacing12),
          ],
          Text(title),
        ],
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusLarge),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text(confirmText),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
          ),
        ),
      ],
    );
  }
}

/// A custom toast notification
void showCMSToast(
    BuildContext context, {
      required String message,
      Color backgroundColor = const Color(0xFF123755),
      Duration duration = const Duration(seconds: 3),
      IconData? icon,
    }) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: CMSDesignSystem.spacing8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
      ),
      margin: EdgeInsets.all(CMSDesignSystem.spacing16),
      duration: duration,
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          scaffold.hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// A custom form field with a label
class CMSFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final bool enabled;

  const CMSFormField({
    Key? key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: CMSDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CMSDesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: CMSDesignSystem.spacing8),
          ],
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              counterText: '',
              filled: true,
              fillColor: enabled ? Colors.white : CMSDesignSystem.disabledBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                borderSide: BorderSide(
                  color: CMSDesignSystem.divider,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                borderSide: BorderSide(
                  color: CMSDesignSystem.divider,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                borderSide: BorderSide(
                  color: CMSDesignSystem.primaryGreen,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: CMSDesignSystem.spacing16,
                vertical: CMSDesignSystem.spacing16,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: enabled ? CMSDesignSystem.textPrimary : CMSDesignSystem.textDisabled,
            ),
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

/// A custom dropdown field with a label
class CMSDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  const CMSDropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: CMSDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CMSDesignSystem.textPrimary,
              ),
            ),
            SizedBox(height: CMSDesignSystem.spacing8),
          ],
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              filled: true,
              fillColor: enabled ? Colors.white : CMSDesignSystem.disabledBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                borderSide: BorderSide(
                  color: CMSDesignSystem.divider,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                borderSide: BorderSide(
                  color: CMSDesignSystem.divider,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
                borderSide: BorderSide(
                  color: CMSDesignSystem.primaryGreen,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: CMSDesignSystem.spacing16,
                vertical: CMSDesignSystem.spacing16,
              ),
            ),
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down_rounded, color: CMSDesignSystem.primaryBlue),
            style: TextStyle(
              fontSize: 16,
              color: enabled ? CMSDesignSystem.textPrimary : CMSDesignSystem.textDisabled,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

/// A custom button with optional icon and gradient
class CMSButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double width;
  final double height;

  const CMSButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.width = double.infinity,
    this.height = 54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColor = isOutlined
        ? textColor ?? CMSDesignSystem.primaryGreen
        : color ?? CMSDesignSystem.primaryGreen;

    final bgColor = isOutlined ? Colors.transparent : defaultColor;
    final fgColor = isOutlined ? defaultColor : textColor ?? Colors.white;
    final borderColor = isOutlined ? defaultColor : Colors.transparent;

    return Container(
      width: width,
      height: height,
      child: isOutlined
          ? OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          ),
        ),
        child: _buildButtonContent(fgColor),
      )
          : ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          ),
        ),
        child: _buildButtonContent(fgColor),
      ),
    );
  }

  Widget _buildButtonContent(Color color) {
    return isLoading
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          SizedBox(width: CMSDesignSystem.spacing8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A custom avatar widget
class CMSAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String name;

  const CMSAvatar({
    Key? key,
    this.imageUrl,
    required this.name,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('')
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage ? Colors.transparent : CMSDesignSystem.primaryBlue.withOpacity(0.2),
        border: Border.all(
          color: CMSDesignSystem.divider,
          width: 1,
        ),
      ),
      child: hasImage
          ? ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CMSDesignSystem.primaryBlue,
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Text(
              initials.substring(0, initials.length > 2 ? 2 : initials.length),
              style: TextStyle(
                fontSize: size / 3,
                fontWeight: FontWeight.bold,
                color: CMSDesignSystem.primaryBlue,
              ),
            ),
          ),
        ),
      )
          : Center(
        child: Text(
          initials.substring(0, initials.length > 2 ? 2 : initials.length),
          style: TextStyle(
            fontSize: size / 3,
            fontWeight: FontWeight.bold,
            color: CMSDesignSystem.primaryBlue,
          ),
        ),
      ),
    );
  }
}