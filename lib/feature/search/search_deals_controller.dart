import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;
  final Duration debounceDuration;

  SearchDealsController({
    required this.dealRepo,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  Timer? _debounce;

  int _latestRequestId = 0;

  void onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _latestRequestId++;
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }
    _debounce = Timer(debounceDuration, () => _search(query));
  }

  Future<void> _search(String query) async {
    final requestId = ++_latestRequestId;
    isLoading.value = true;
    hasSearched.value = true;
    try {
      final found = await dealRepo.search(query);
      if (requestId != _latestRequestId) {
        LogService.log('search: dropped stale results for "$query"');
        return;
      }
      results.assignAll(found);
    } catch (e) {
      if (requestId != _latestRequestId) return;
      LogService.error('search failed', e);
    } finally {
      if (requestId == _latestRequestId) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _latestRequestId++;
    super.onClose();
  }
}
