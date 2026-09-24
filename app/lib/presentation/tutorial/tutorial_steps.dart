import 'package:flutter/widgets.dart';

enum TutorialTrack {
  firstLaunch,
  add,
  finance,
  backup,
  transactions,
  statistics,
  full,
}

enum TutorialStep {
  welcome,
  addButton,
  amount,
  category,
  save,
  txList,
  txFilters,
  statsMonth,
  statsCategories,
  income,
  recurring,
  spending,
  backup,
  restore,
}

enum TutorialHoleShape { roundedRect, circle }

class TutorialCopy {
  const TutorialCopy({required this.title, required this.description});

  final String title;
  final String description;
}

extension TutorialTrackX on TutorialTrack {
  List<TutorialStep> get steps => switch (this) {
    TutorialTrack.firstLaunch => const [
      TutorialStep.welcome,
      TutorialStep.addButton,
    ],
    TutorialTrack.add => const [
      TutorialStep.amount,
      TutorialStep.category,
      TutorialStep.save,
    ],
    TutorialTrack.finance => const [
      TutorialStep.income,
      TutorialStep.recurring,
      TutorialStep.spending,
    ],
    TutorialTrack.backup => const [TutorialStep.backup, TutorialStep.restore],
    TutorialTrack.transactions => const [
      TutorialStep.txList,
      TutorialStep.txFilters,
    ],
    TutorialTrack.statistics => const [
      TutorialStep.statsMonth,
      TutorialStep.statsCategories,
    ],
    TutorialTrack.full => const [
      TutorialStep.welcome,
      TutorialStep.addButton,
      TutorialStep.amount,
      TutorialStep.category,
      TutorialStep.save,
      TutorialStep.txList,
      TutorialStep.txFilters,
      TutorialStep.statsMonth,
      TutorialStep.statsCategories,
      TutorialStep.income,
      TutorialStep.recurring,
      TutorialStep.spending,
      TutorialStep.backup,
      TutorialStep.restore,
    ],
  };

  bool get resetsShell =>
      this == TutorialTrack.firstLaunch || this == TutorialTrack.full;

  bool get returnsToSettings => this == TutorialTrack.full;
}

extension TutorialStepX on TutorialStep {
  TutorialCopy get copy => switch (this) {
    TutorialStep.welcome => const TutorialCopy(
      title: 'Chào mừng đến với Tiền đâu nè',
      description:
          'Quản lý thu nhập, khoản định kỳ và chi tiêu của bạn thật đơn giản.',
    ),
    TutorialStep.addButton => const TutorialCopy(
      title: 'Thêm giao dịch',
      description: 'Nhấn nút + để thêm nhanh một giao dịch mới.',
    ),
    TutorialStep.amount => const TutorialCopy(
      title: 'Nhập số tiền',
      description: 'Gõ số tiền hoặc chọn nhanh 10k, 20k, 50k, 100k, 200k.',
    ),
    TutorialStep.category => const TutorialCopy(
      title: 'Chọn khoản chi',
      description: 'Chọn danh mục phù hợp để biết tiền đi đâu.',
    ),
    TutorialStep.save => const TutorialCopy(
      title: 'Lưu giao dịch',
      description: 'Nhấn Lưu để ghi nhận khoản chi và quay lại Trang chủ.',
    ),
    TutorialStep.txList => const TutorialCopy(
      title: 'Danh sách giao dịch',
      description:
          'Theo ngày, bạn xem timeline và tổng chi của ngày đang chọn.',
    ),
    TutorialStep.txFilters => const TutorialCopy(
      title: 'Lọc giao dịch',
      description:
          'Chuyển sang Theo tháng để xem cả tháng và lọc theo danh mục.',
    ),
    TutorialStep.statsMonth => const TutorialCopy(
      title: 'Chi tiêu tháng này',
      description:
          'Tổng chi trong tháng đang xem, kèm thay đổi so với tháng trước.',
    ),
    TutorialStep.statsCategories => const TutorialCopy(
      title: 'Chi tiêu theo danh mục',
      description: 'Xem tiền đi vào từng danh mục và danh mục chi nhiều nhất.',
    ),
    TutorialStep.income => const TutorialCopy(
      title: 'Thu nhập của bạn',
      description:
          'Đây là nơi ghi nhận số tiền bạn kiếm được, như lương và các khoản thu nhập khác.',
    ),
    TutorialStep.recurring => const TutorialCopy(
      title: 'Khoản định kỳ',
      description:
          'Những khoản tiền cố định hoặc lặp lại sẽ được quản lý tại đây để bạn luôn biết mình cần chi bao nhiêu.',
    ),
    TutorialStep.spending => const TutorialCopy(
      title: 'Chi tiêu',
      description:
          'Mỗi khoản chi sẽ được ghi nhận để bạn biết số tiền còn lại của mình.',
    ),
    TutorialStep.backup => const TutorialCopy(
      title: 'Sao lưu dữ liệu',
      description:
          'Tạo file .tdn để giữ an toàn thu nhập, khoản định kỳ và chi tiêu của bạn.',
    ),
    TutorialStep.restore => const TutorialCopy(
      title: 'Khôi phục dữ liệu',
      description:
          'Dùng bản sao lưu để khôi phục dữ liệu khi đổi máy hoặc cài lại app.',
    ),
  };

  bool get usesFinance =>
      this == TutorialStep.income ||
      this == TutorialStep.recurring ||
      this == TutorialStep.spending;

  bool get usesAdd =>
      this == TutorialStep.amount ||
      this == TutorialStep.category ||
      this == TutorialStep.save;

  bool get usesBackup =>
      this == TutorialStep.backup || this == TutorialStep.restore;

  bool get usesTransactions =>
      this == TutorialStep.txList || this == TutorialStep.txFilters;

  bool get usesStatistics =>
      this == TutorialStep.statsMonth || this == TutorialStep.statsCategories;

  TutorialHoleShape get holeShape => this == TutorialStep.addButton
      ? TutorialHoleShape.circle
      : TutorialHoleShape.roundedRect;

  bool get preferTooltipAbove =>
      this == TutorialStep.addButton || this == TutorialStep.save;

  double holeRadius(Size targetSize) {
    if (holeShape == TutorialHoleShape.circle) {
      return targetSize.shortestSide / 2;
    }
    final shortest = targetSize.shortestSide;
    return (shortest * 0.12).clamp(16.0, 28.0);
  }

  TutorialStep? nextIn(TutorialTrack track) {
    final steps = track.steps;
    final index = steps.indexOf(this);
    if (index < 0 || index >= steps.length - 1) return null;
    return steps[index + 1];
  }

  bool isLastIn(TutorialTrack track) {
    final steps = track.steps;
    return steps.isNotEmpty && steps.last == this;
  }
}
