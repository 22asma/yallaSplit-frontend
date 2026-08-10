import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import '../../data/datasources/addition_api_service.dart';
import '../../data/dto/addition_dtos.dart';
import '../../data/modals/addition_model.dart';
import '../../data/modals/scanned_receipt_model.dart';

enum ScanStatus { idle, scanning, scanned, creating, error }

class ScanReceiptState {
  final ScanStatus status;
  final ScannedReceiptModel? receipt;
  final List<ScannedArticle> editableArticles;
  final String? errorMessage;
  final AdditionModel? createdAddition;

  const ScanReceiptState({
    this.status = ScanStatus.idle,
    this.receipt,
    this.editableArticles = const [],
    this.errorMessage,
    this.createdAddition,
  });

  double get total => receipt?.montantTotal ?? 0;

  ScanReceiptState copyWith({
    ScanStatus? status,
    ScannedReceiptModel? receipt,
    List<ScannedArticle>? editableArticles,
    String? errorMessage,
    AdditionModel? createdAddition,
    bool clearError = false,
  }) {
    return ScanReceiptState(
      status: status ?? this.status,
      receipt: receipt ?? this.receipt,
      editableArticles: editableArticles ?? this.editableArticles,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdAddition: createdAddition ?? this.createdAddition,
    );
  }
}

class ScanReceiptNotifier extends StateNotifier<ScanReceiptState> {
  final AdditionApiService _api;

  ScanReceiptNotifier(this._api) : super(const ScanReceiptState());

  Future<void> scan(Uint8List imageBytes, String filename) async {
    state = state.copyWith(status: ScanStatus.scanning, clearError: true);
    try {
      final receipt = await _api.scanRecu(imageBytes, filename);
      state = state.copyWith(
        status: ScanStatus.scanned,
        receipt: receipt,
        editableArticles: receipt.articles,
      );
    } on AppException catch (e) {
      state = state.copyWith(status: ScanStatus.error, errorMessage: e.message);
    }
  }

  void updateArticle(int index, ScannedArticle updated) {
    final list = [...state.editableArticles];
    list[index] = updated;
    state = state.copyWith(editableArticles: list);
  }

  void removeArticle(int index) {
    final list = [...state.editableArticles]..removeAt(index);
    state = state.copyWith(editableArticles: list);
  }

  void addEmptyArticle() {
    state = state.copyWith(
      editableArticles: [
        ...state.editableArticles,
        const ScannedArticle(nom: '', prix: 0, quantite: 1),
      ],
    );
  }

  Future<bool> confirmAndCreate() async {
    if (state.receipt == null) return false;
    state = state.copyWith(status: ScanStatus.creating, clearError: true);

    try {
      final dto = CreateAdditionRequestDto(
        montantTotal: state.total,
        taxe: state.receipt!.taxe,
        imageRecuUrl: state.receipt!.imageRecuUrl,
        articles: state.editableArticles
            .map((a) => CreateArticleRequestDto.fromScanned(a))
            .toList(),
      );
      final addition = await _api.create(dto);
      state = state.copyWith(status: ScanStatus.scanned, createdAddition: addition);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(status: ScanStatus.error, errorMessage: e.message);
      return false;
    }
  }

  void reset() {
    state = const ScanReceiptState();
  }
}