import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ssh_tab.dart';
import '../models/ssh_connection.dart';

/// SSH 标签页管理控制器
class SshTabController extends ChangeNotifier {
  static const int maxTabs = 10;
  final List<SshTab> _tabs = [];
  int _activeTabIndex = -1;
  
  final _uuid = const Uuid();

  /// 获取所有标签页
  List<SshTab> get tabs => List.unmodifiable(_tabs);

  /// 获取当前活跃标签页
  SshTab? get activeTab => _activeTabIndex >= 0 && _activeTabIndex < _tabs.length 
      ? _tabs[_activeTabIndex] 
      : null;

  /// 获取当前活跃标签页索引
  int get activeTabIndex => _activeTabIndex;

  /// 是否已达到最大标签页数量
  bool get isMaxTabsReached => _tabs.length >= maxTabs;

  /// 检查连接是否已经打开
  bool isConnectionOpen(String connectionId) {
    return _tabs.any((tab) => tab.connectionId == connectionId);
  }

  /// 添加新标签页
  String? addTab(SshConnection connection) {
    // 检查是否已达到最大标签页数量
    if (isMaxTabsReached) {
      return null;
    }

    // 检查连接是否已经打开，如果是则切换到该标签页
    final existingTabIndex = _tabs.indexWhere((tab) => tab.connectionId == connection.id);
    if (existingTabIndex != -1) {
      switchToTab(existingTabIndex);
      return _tabs[existingTabIndex].id;
    }

    // 创建新标签页
    final tabId = _uuid.v4();
    final newTab = SshTab(
      id: tabId,
      connectionId: connection.id,
      connection: connection,
      createdAt: DateTime.now(),
    );

    _tabs.add(newTab);
    
    // 设置新标签页为活跃状态
    _setActiveTab(_tabs.length - 1);
    
    notifyListeners();
    return tabId;
  }

  /// 关闭标签页
  bool closeTab(String tabId) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return false;

    _tabs.removeAt(tabIndex);

    // 调整活跃标签页索引
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    } else if (_activeTabIndex > tabIndex) {
      _activeTabIndex--;
    }

    // 如果关闭的是当前活跃标签页，需要重新设置活跃状态
    if (_activeTabIndex >= 0 && _activeTabIndex < _tabs.length) {
      _setActiveTab(_activeTabIndex);
    } else {
      _activeTabIndex = -1;
    }

    notifyListeners();
    return true;
  }

  /// 根据索引关闭标签页
  bool closeTabByIndex(int index) {
    if (index < 0 || index >= _tabs.length) return false;
    return closeTab(_tabs[index].id);
  }

  /// 切换到指定标签页
  void switchToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    
    _setActiveTab(index);
    notifyListeners();
  }

  /// 根据标签页ID切换
  void switchToTabById(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      switchToTab(index);
    }
  }

  /// 设置活跃标签页
  void _setActiveTab(int index) {
    // 清除所有标签页的活跃状态
    for (var tab in _tabs) {
      tab.isActive = false;
    }

    // 设置新的活跃标签页
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      _tabs[index].isActive = true;
    } else {
      _activeTabIndex = -1;
    }
  }

  /// 关闭所有标签页
  void closeAllTabs() {
    _tabs.clear();
    _activeTabIndex = -1;
    notifyListeners();
  }

  /// 获取标签页信息
  SshTab? getTab(String tabId) {
    try {
      return _tabs.firstWhere((tab) => tab.id == tabId);
    } catch (e) {
      return null;
    }
  }

  /// 获取标签页的连接ID
  String? getConnectionId(String tabId) {
    final tab = getTab(tabId);
    return tab?.connectionId;
  }

  /// 移动标签页位置
  void moveTab(int from, int to) {
    if (from < 0 || from >= _tabs.length || to < 0 || to >= _tabs.length) {
      return;
    }

    final tab = _tabs.removeAt(from);
    _tabs.insert(to, tab);

    // 调整活跃标签页索引
    if (_activeTabIndex == from) {
      _activeTabIndex = to;
    } else if (_activeTabIndex > from && _activeTabIndex <= to) {
      _activeTabIndex--;
    } else if (_activeTabIndex < from && _activeTabIndex >= to) {
      _activeTabIndex++;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _tabs.clear();
    super.dispose();
  }
}