import 'package:flutter/foundation.dart';
import 'app_module.dart';

class ModuleRegistry extends ChangeNotifier {
  final Map<String, AppModule> _modules = {};
  final Map<String, bool> _activeStatus = {};

  List<AppModule> get registeredModules => _modules.values.toList();
  List<AppModule> get allModules => _modules.values.toList();

  List<AppModule> get activeModules {
    return _modules.values.where((m) => _activeStatus[m.moduleId] ?? true).toList();
  }

  bool isModuleActive(String moduleId) {
    return _activeStatus[moduleId] ?? true;
  }

  void registerModule(AppModule module, {bool initialActive = true}) {
    _modules[module.moduleId] = module;
    _activeStatus[module.moduleId] = initialActive;
    notifyListeners();
  }

  void setModuleActive(String moduleId, bool isActive) {
    if (_modules.containsKey(moduleId)) {
      _activeStatus[moduleId] = isActive;
      notifyListeners();
    }
  }

  void toggleModule(String moduleId, [bool? targetState]) {
    if (_modules.containsKey(moduleId)) {
      final current = _activeStatus[moduleId] ?? true;
      _activeStatus[moduleId] = targetState ?? !current;
      notifyListeners();
    }
  }

  void loadFromBackend(Map<String, bool> serverStatus) {
    _activeStatus.addAll(serverStatus);
    notifyListeners();
  }
}
