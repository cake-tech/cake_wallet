import "dart:math";
import "dart:ui";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/more_actions_modal.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/new_main_navbar_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class MoreActionsButton extends StatefulWidget {
  const MoreActionsButton({required this.dashboardViewModel, super.key});

  final DashboardViewModel dashboardViewModel;

  @override
  State<MoreActionsButton> createState() => _MoreActionsButtonState();
}

class _MoreActionsButtonState extends State<MoreActionsButton> with SingleTickerProviderStateMixin {
  static const _panelPadding = 18.0;
  static const _screenGutter = 16.0;
  static const _borderWidth = 1.0;

  final _portalController = OverlayPortalController();
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(_portalController.hide);
      }
    });
  late final _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
    reverseCurve: Curves.easeInOutCubic,
  );
  LocalHistoryEntry? _historyEntry;
  bool _upsideDown = false;
  List<ExtraAction> _actions = const [];

  @override
  void dispose() {
    _historyEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    HapticFeedback.mediumImpact();
    _upsideDown = Random().nextInt(10000) == 0;
    _actions =
        ExtraAction.all.where((action) => action.applicable(widget.dashboardViewModel)).toList();
    _historyEntry = LocalHistoryEntry(onRemove: _animateClosed);
    ModalRoute.of(context)?.addLocalHistoryEntry(_historyEntry!);
    setState(_portalController.show);
    _controller.forward();
  }

  void _collapse() {
    HapticFeedback.mediumImpact();
    _historyEntry?.remove();
  }

  double get _gridHeight {
    final rows = (_actions.length / MoreActionsGrid.crossAxisCount).ceil();
    return rows * MoreActionsGrid.itemExtent + (rows - 1) * MoreActionsGrid.spacing;
  }

  void _animateClosed() {
    _historyEntry = null;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: _buildPanel,
        child: Opacity(
          opacity: _portalController.isShowing ? 0 : 1,
          child: GestureDetector(onTap: _expand, child: _buildSurface(0, child: _buildIcon(0))),
        ),
      );

  Widget _buildPanel(BuildContext context) {
    final buttonBox = this.context.findRenderObject()! as RenderBox;
    final overlayBox = Overlay.of(this.context).context.findRenderObject()! as RenderBox;
    final buttonRect = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox) & buttonBox.size;
    final expandedRect = Rect.fromLTRB(
      _screenGutter,
      buttonRect.bottom - NewMainNavBar.barHeight - _gridHeight - _panelPadding * 2,
      overlayBox.size.width - _screenGutter,
      buttonRect.bottom,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _collapse,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.3 * _animation.value)),
            ),
          ),
          Positioned.fromRect(
            rect: Rect.lerp(buttonRect, expandedRect, _animation.value)!,
            child: _buildSurface(
              _animation.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (expandedRect.left - buttonRect.left) * (1 - _animation.value) -
                        _borderWidth,
                    top:
                        (expandedRect.top - buttonRect.top) * (1 - _animation.value) - _borderWidth,
                    width: expandedRect.width,
                    height: expandedRect.height,
                    child: Opacity(
                      opacity: const Interval(0.4, 1).transform(_animation.value),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _panelPadding, _panelPadding, _panelPadding, 0),
                        child: Column(
                          spacing: _panelPadding,
                          children: [
                            MoreActionsGrid(
                              actions: _actions,
                              dashboardViewModel: widget.dashboardViewModel,
                              onActionOpened: _collapse,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fromRect(
            rect: buttonRect,
            child: GestureDetector(onTap: _collapse, child: _buildIcon(_animation.value)),
          ),
        ],
      ),
    );
  }

  Widget _buildSurface(double progress, {required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(NewMainNavBar.barHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            width: NewMainNavBar.barHeight,
            height: NewMainNavBar.barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NewMainNavBar.barHeight / 2),
              color: Color.lerp(
                Theme.of(context).colorScheme.surfaceContainer.withAlpha(127),
                Theme.of(context).colorScheme.surface.withAlpha(242),
                progress,
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
                width: _borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      );

  Widget _buildIcon(double progress) => Semantics(
        button: true,
        label: progress == 0 ? S.of(context).more_actions : S.of(context).close,
        child: Transform.rotate(
          angle: progress * pi / 4,
          child: Icon(
            Icons.add,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
