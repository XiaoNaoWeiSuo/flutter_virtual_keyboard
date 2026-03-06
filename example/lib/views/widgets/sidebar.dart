import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class LayoutSidebar extends StatelessWidget {
  const LayoutSidebar({
    super.key,
    required this.selectedId,
    required this.ids,
    required this.names,
    required this.onSelect,
    required this.onNew,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExport,
    required this.onImport,
    required this.onCopy,
  });

  final String selectedId;
  final List<String> ids;
  final Map<String, String> names;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(2, 0),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.game_controller_solid,
                    size: 18,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gamepad Pro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                final name = names[id] ?? id;
                final isSelected = id == selectedId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.blue.shade700 : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isSelected
                          ? BorderSide(
                              color: Colors.blue.withValues(alpha: 0.1),
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.blue.withValues(alpha: 0.08),
                    hoverColor: Colors.black.withValues(alpha: 0.03),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () => onSelect(id),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    trailing: isSelected
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              color: Colors.grey.withValues(alpha: 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SidebarButton(
                  icon: CupertinoIcons.add,
                  label: '新建布局',
                  onTap: onNew,
                  textColor: Colors.blue.shade600,
                  backgroundColor: Colors.blue.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SidebarButton(
                        icon: CupertinoIcons.arrow_up_doc,
                        label: '导入',
                        onTap: onImport,
                        isSmall: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    MenuAnchor(
                      style: MenuStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll(Colors.white),
                        surfaceTintColor:
                            const WidgetStatePropertyAll(Colors.white),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 8),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        elevation: const WidgetStatePropertyAll(6),
                        shadowColor: WidgetStatePropertyAll(
                          Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                      builder: (context, controller, child) {
                        return SidebarButton(
                          icon: CupertinoIcons.ellipsis_circle,
                          label: '更多',
                          onTap: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          isSmall: true,
                        );
                      },
                      menuChildren: [
                        SidebarMenuItem(
                          onPressed: onCopy,
                          icon: CupertinoIcons.doc_on_clipboard,
                          label: '一键复制 JSON',
                        ),
                        SidebarMenuItem(
                          onPressed: onDuplicate,
                          icon: CupertinoIcons.doc_on_doc,
                          label: '复制当前布局',
                        ),
                        SidebarMenuItem(
                          onPressed: onExport,
                          icon: CupertinoIcons.arrow_down_doc,
                          label: '导出 JSON',
                        ),
                        const Divider(height: 16),
                        SidebarMenuItem(
                          onPressed: ids.length <= 1 ? null : onDelete,
                          icon: CupertinoIcons.trash,
                          label: '删除',
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarButton extends StatefulWidget {
  const SidebarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor = Colors.black87,
    this.backgroundColor = Colors.transparent,
    this.isSmall = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color backgroundColor;
  final bool isSmall;

  @override
  State<SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.backgroundColor == Colors.transparent
                    ? Colors.black.withValues(alpha: 0.05)
                    : widget.backgroundColor.withValues(alpha: 0.15))
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.backgroundColor == Colors.transparent
                ? Border.all(color: Colors.grey.withValues(alpha: 0.2))
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmall ? 8 : 12,
            vertical: widget.isSmall ? 8 : 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.isSmall ? 16 : 18,
                color: widget.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFF5F5F7);
          }
          return null;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(200, 40)),
      ),
      leadingIcon: Icon(
        icon,
        size: 18,
        color: onPressed == null
            ? Colors.grey
            : (isDestructive ? Colors.red : Colors.black87),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onPressed == null
              ? Colors.grey
              : (isDestructive ? Colors.red : Colors.black87),
          fontSize: 14,
        ),
      ),
    );
  }
}
