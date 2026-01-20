import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class FloatingActionMenu extends StatefulWidget {
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onAddToWidget;
  final bool isBookmarked;

  const FloatingActionMenu({
    super.key,
    this.onBookmark,
    this.onShare,
    this.onAddToWidget,
    this.isBookmarked = false,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Column(
                  children: [
                    if (widget.onAddToWidget != null)
                      _buildActionButton(
                        icon: Icons.widgets,
                        onPressed: widget.onAddToWidget!,
                        backgroundColor: Colors.purple,
                      ),
                    const SizedBox(height: 8),
                    if (widget.onShare != null)
                      _buildActionButton(
                        icon: Icons.share,
                        onPressed: widget.onShare!,
                        backgroundColor: AppConstants.warmGoldAccent,
                      ),
                    const SizedBox(height: 8),
                    if (widget.onBookmark != null)
                      _buildActionButton(
                        icon: widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        onPressed: widget.onBookmark!,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
        FloatingActionButton(
          heroTag: 'fab_menu',
          onPressed: _toggle,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isExpanded ? Icons.close : Icons.more_vert,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
