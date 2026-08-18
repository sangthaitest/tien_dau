import '../../domain/failures/app_failure.dart';

abstract final class AddTransactionCopy {
  static const title = 'Thêm giao dịch';
  static const save = 'Lưu giao dịch';
  static const amountLabel = 'Số tiền';
  static const chiCho = 'Chi cho';
  static const detail = 'Chi tiết';
  static const payWith = 'Thanh toán bằng';
  static const date = 'Ngày';
  static const time = 'Giờ';
  static const note = 'Ghi chú (tuỳ chọn)';
  static const noteHint = 'Thêm ghi chú...';
  static const amountRequired = 'Vui lòng nhập số tiền';
  static const saveFailed = 'Không lưu được giao dịch. Thử lại.';

  static String messageFor(AppFailure failure) {
    if (failure is ValidationFailure && failure.message.contains('Amount')) {
      return amountRequired;
    }
    if (failure is PersistenceFailure) {
      return saveFailed;
    }
    return failure.message;
  }
}
