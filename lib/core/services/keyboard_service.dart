import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardService {
  static final KeyboardService _instance = KeyboardService._internal();
  factory KeyboardService() => _instance;
  KeyboardService._internal();

  // Scroll controllers for different screens
  ScrollController? _mainScrollController;
  ScrollController? _currentScrollController;

  // Navigation callbacks
  VoidCallback? _onPreviousPage;
  VoidCallback? _onNextPage;
  VoidCallback? _onClose;
  VoidCallback? _onToggleFullscreen;
  VoidCallback? _onAddHabit;
  VoidCallback? _onOpenSettings;
  VoidCallback? _onOpenAnalytics;
  VoidCallback? _onToggleArchive;
  VoidCallback? _onFilterByCategory;
  VoidCallback? _onBulkEdit;
  VoidCallback? _onBackup;
  VoidCallback? _onYearReview;
  VoidCallback? _onAchievements;
  VoidCallback? _onPoints;
  VoidCallback? _onShowKeyboardShortcuts;

  // Focus management
  FocusNode? _currentFocusNode;
  List<FocusNode> _focusableNodes = [];

  // Zoom level management
  double _currentZoomLevel = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.1;

  // Initialize the keyboard service
  void initialize({
    ScrollController? mainScrollController,
    VoidCallback? onPreviousPage,
    VoidCallback? onNextPage,
    VoidCallback? onClose,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onAddHabit,
    VoidCallback? onOpenSettings,
    VoidCallback? onOpenAnalytics,
    VoidCallback? onToggleArchive,
    VoidCallback? onFilterByCategory,
    VoidCallback? onBulkEdit,
    VoidCallback? onBackup,
    VoidCallback? onYearReview,
    VoidCallback? onAchievements,
    VoidCallback? onPoints,
    VoidCallback? onShowKeyboardShortcuts,
  }) {
    _mainScrollController = mainScrollController;
    _currentScrollController = mainScrollController;
    _onPreviousPage = onPreviousPage;
    _onNextPage = onNextPage;
    _onClose = onClose;
    _onToggleFullscreen = onToggleFullscreen;
    _onAddHabit = onAddHabit;
    _onOpenSettings = onOpenSettings;
    _onOpenAnalytics = onOpenAnalytics;
    _onToggleArchive = onToggleArchive;
    _onFilterByCategory = onFilterByCategory;
    _onBulkEdit = onBulkEdit;
    _onBackup = onBackup;
    _onYearReview = onYearReview;
    _onAchievements = onAchievements;
    _onPoints = onPoints;
    _onShowKeyboardShortcuts = onShowKeyboardShortcuts;
  }

  // Set the current scroll controller
  void setScrollController(ScrollController? controller) {
    _currentScrollController = controller ?? _mainScrollController;
  }

  // Set focusable nodes for tab navigation
  void setFocusableNodes(List<FocusNode> nodes) {
    _focusableNodes = nodes;
  }

  // Add a focusable node
  void addFocusableNode(FocusNode node) {
    if (!_focusableNodes.contains(node)) {
      _focusableNodes.add(node);
    }
  }

  // Remove a focusable node
  void removeFocusableNode(FocusNode node) {
    _focusableNodes.remove(node);
  }

  // Handle keyboard events
  bool handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      return _handleKeyDown(event);
    }
    return false;
  }

  bool _handleKeyDown(RawKeyDownEvent event) {
    // Check for modifier keys
    final isAltPressed = event.isAltPressed;
    final isCtrlPressed = event.isControlPressed;
    final isShiftPressed = event.isShiftPressed;

    // Navigation shortcuts
    if (isAltPressed && !isCtrlPressed && !isShiftPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          _onPreviousPage?.call();
          return true;
        case LogicalKeyboardKey.arrowRight:
          _onNextPage?.call();
          return true;
      }
    }

    // Close shortcuts
    if (isCtrlPressed && !isAltPressed && !isShiftPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyW:
          _onClose?.call();
          return true;
      }
    }

    // Function keys
    switch (event.logicalKey) {
      case LogicalKeyboardKey.f1:
        _onShowKeyboardShortcuts?.call();
        return true;
      case LogicalKeyboardKey.f11:
        _onToggleFullscreen?.call();
        return true;
    }

    // Scroll shortcuts
    if (!isAltPressed && !isCtrlPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          _scrollUp();
          return true;
        case LogicalKeyboardKey.arrowDown:
          _scrollDown();
          return true;
        case LogicalKeyboardKey.pageUp:
          _scrollPageUp();
          return true;
        case LogicalKeyboardKey.pageDown:
          _scrollPageDown();
          return true;
        case LogicalKeyboardKey.space:
          if (!isShiftPressed) {
            _scrollPageDown();
          } else {
            _scrollPageUp();
          }
          return true;
        case LogicalKeyboardKey.home:
          _scrollToTop();
          return true;
        case LogicalKeyboardKey.end:
          _scrollToBottom();
          return true;
      }
    }

    // Zoom shortcuts
    if (isCtrlPressed && !isAltPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.equal:
        case LogicalKeyboardKey.numpadAdd:
          _zoomIn();
          return true;
        case LogicalKeyboardKey.minus:
        case LogicalKeyboardKey.numpadSubtract:
          _zoomOut();
          return true;
        case LogicalKeyboardKey.digit0:
        case LogicalKeyboardKey.numpad0:
          _resetZoom();
          return true;
      }
    }

    // Tab navigation
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (isShiftPressed) {
        _focusPrevious();
      } else {
        _focusNext();
      }
      return true;
    }

    // Enter key to activate focused element
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _activateFocusedElement();
      return true;
    }

    // Quick action shortcuts
    if (!isAltPressed && !isCtrlPressed && !isShiftPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyA:
          _onAddHabit?.call();
          return true;
        case LogicalKeyboardKey.keyS:
          _onOpenSettings?.call();
          return true;
        case LogicalKeyboardKey.keyD:
          _onOpenAnalytics?.call();
          return true;
        case LogicalKeyboardKey.keyF:
          _onFilterByCategory?.call();
          return true;
        case LogicalKeyboardKey.keyB:
          _onBulkEdit?.call();
          return true;
        case LogicalKeyboardKey.keyI:
          _onBackup?.call();
          return true;
        case LogicalKeyboardKey.keyY:
          _onYearReview?.call();
          return true;
        case LogicalKeyboardKey.keyP:
          _onPoints?.call();
          return true;
        case LogicalKeyboardKey.keyR:
          _onAchievements?.call();
          return true;
      }
    }

    return false;
  }

  // Scroll methods
  void _scrollUp() {
    if (_currentScrollController?.hasClients == true) {
      _currentScrollController!.animateTo(
        _currentScrollController!.offset - 50,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollDown() {
    if (_currentScrollController?.hasClients == true) {
      _currentScrollController!.animateTo(
        _currentScrollController!.offset + 50,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollPageUp() {
    if (_currentScrollController?.hasClients == true) {
      final viewportHeight = _currentScrollController!.position.viewportDimension;
      _currentScrollController!.animateTo(
        _currentScrollController!.offset - viewportHeight,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollPageDown() {
    if (_currentScrollController?.hasClients == true) {
      final viewportHeight = _currentScrollController!.position.viewportDimension;
      _currentScrollController!.animateTo(
        _currentScrollController!.offset + viewportHeight,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    if (_currentScrollController?.hasClients == true) {
      _currentScrollController!.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToBottom() {
    if (_currentScrollController?.hasClients == true) {
      _currentScrollController!.animateTo(
        _currentScrollController!.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Zoom methods
  void _zoomIn() {
    if (_currentZoomLevel < _maxZoom) {
      _currentZoomLevel = (_currentZoomLevel + _zoomStep).clamp(_minZoom, _maxZoom);
      _applyZoom();
    }
  }

  void _zoomOut() {
    if (_currentZoomLevel > _minZoom) {
      _currentZoomLevel = (_currentZoomLevel - _zoomStep).clamp(_minZoom, _maxZoom);
      _applyZoom();
    }
  }

  void _resetZoom() {
    _currentZoomLevel = 1.0;
    _applyZoom();
  }

  void _applyZoom() {
    // This would need to be implemented based on the specific UI structure
    // For now, we'll just store the zoom level
    print('Zoom level: ${_currentZoomLevel.toStringAsFixed(1)}x');
  }

  // Focus navigation
  void _focusNext() {
    if (_focusableNodes.isEmpty) return;
    
    if (_currentFocusNode == null) {
      _currentFocusNode = _focusableNodes.first;
      _currentFocusNode!.requestFocus();
    } else {
      final currentIndex = _focusableNodes.indexOf(_currentFocusNode!);
      final nextIndex = (currentIndex + 1) % _focusableNodes.length;
      _currentFocusNode = _focusableNodes[nextIndex];
      _currentFocusNode!.requestFocus();
    }
  }

  void _focusPrevious() {
    if (_focusableNodes.isEmpty) return;
    
    if (_currentFocusNode == null) {
      _currentFocusNode = _focusableNodes.last;
      _currentFocusNode!.requestFocus();
    } else {
      final currentIndex = _focusableNodes.indexOf(_currentFocusNode!);
      final previousIndex = (currentIndex - 1 + _focusableNodes.length) % _focusableNodes.length;
      _currentFocusNode = _focusableNodes[previousIndex];
      _currentFocusNode!.requestFocus();
    }
  }

  void _activateFocusedElement() {
    // This would need to be implemented based on the specific UI structure
    // For now, we'll just print a message
    if (_currentFocusNode != null) {
      print('Activating focused element');
    }
  }

  // Get current zoom level
  double get currentZoomLevel => _currentZoomLevel;

  // Dispose resources
  void dispose() {
    _mainScrollController = null;
    _currentScrollController = null;
    _focusableNodes.clear();
    _currentFocusNode = null;
  }
}