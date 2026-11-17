// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Sure Finances';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonTryAgain => 'Thử lại';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonAll => 'Tất cả';

  @override
  String get commonRefresh => 'Làm mới';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonUndo => 'Hoàn tác';

  @override
  String get chatSuggestionNetWorth =>
      'Giá trị tài sản ròng hiện tại của tôi là bao nhiêu?';

  @override
  String get chatSuggestionSpending =>
      'Chi tiêu của tôi thay đổi như thế nào trong tháng này?';

  @override
  String get chatSuggestionSavings =>
      'Làm thế nào để cải thiện tỷ lệ tiết kiệm của tôi?';

  @override
  String get chatSuggestionExpenses =>
      'Những khoản chi lớn nhất gần đây của tôi là gì?';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailRequired => 'Vui lòng nhập email';

  @override
  String get loginEmailInvalid => 'Vui lòng nhập email hợp lệ';

  @override
  String get loginPasswordLabel => 'Mật khẩu';

  @override
  String get loginPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get loginSignIn => 'Đăng nhập';

  @override
  String get loginSignInWithGoogle => 'Đăng nhập bằng Google';

  @override
  String get loginMfaLabel => 'Mã xác thực';

  @override
  String get loginApiKeyLabel => 'Khóa API';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navIntro => 'Giới thiệu';

  @override
  String get navAssistant => 'Trợ lý';

  @override
  String get navMore => 'Thêm';

  @override
  String get dashboardSyncError => 'Đồng bộ thất bại';

  @override
  String get dashboardSyncFailed => 'Đồng bộ thất bại. Vui lòng thử lại.';

  @override
  String get dashboardRefreshing => 'Đang làm mới tài khoản…';

  @override
  String get dashboardAccountsUpdated => 'Đã cập nhật tài khoản';

  @override
  String get dashboardSyncing => 'Đang đồng bộ dữ liệu từ máy chủ…';

  @override
  String get dashboardSynced => 'Đã đồng bộ';

  @override
  String get dashboardErrorLoadingAccounts => 'Không thể tải tài khoản';

  @override
  String get dashboardNoAccounts => 'Chưa có tài khoản';

  @override
  String get dashboardNoAccountsSubtitle =>
      'Thêm tài khoản trên ứng dụng web để xem tại đây.';

  @override
  String get dashboardFilterEmpty =>
      'Không có tài khoản phù hợp với bộ lọc hiện tại';

  @override
  String get chatListTitle => 'Cuộc trò chuyện';

  @override
  String get chatListNewChat => 'Cuộc trò chuyện mới';

  @override
  String get chatListEmpty => 'Chưa có cuộc trò chuyện';

  @override
  String get chatListEmptySubtitle =>
      'Bắt đầu trò chuyện với trợ lý AI của bạn';

  @override
  String get chatListDeleteTitle => 'Xóa cuộc trò chuyện';

  @override
  String get chatConversationNewTitle => 'Cuộc trò chuyện mới';

  @override
  String get chatConversationMessageHint =>
      'Hỏi bất cứ điều gì về tài chính của bạn…';

  @override
  String chatConversationGreetingWithName(String firstName) {
    return 'Chào $firstName, tôi có thể giúp gì cho bạn?';
  }

  @override
  String get chatConversationGreetingNoName =>
      'Xin chào, tôi có thể giúp gì cho bạn?';

  @override
  String get transactionFormNewTitle => 'Giao dịch mới';

  @override
  String get transactionFormTypeLabel => 'Loại';

  @override
  String get transactionFormTypeExpense => 'Khoản chi';

  @override
  String get transactionFormTypeIncome => 'Thu nhập';

  @override
  String get transactionFormAmountLabel => 'Số tiền';

  @override
  String get transactionFormAmountRequired => 'Vui lòng nhập số tiền';

  @override
  String get transactionFormAmountInvalid => 'Vui lòng nhập số tiền hợp lệ';

  @override
  String get transactionFormDateLabel => 'Ngày';

  @override
  String get transactionFormNameLabel => 'Tên';

  @override
  String get transactionFormCategoryLabel => 'Danh mục';

  @override
  String get transactionEditTitle => 'Sửa giao dịch';

  @override
  String get transactionEditNameLabel => 'Tên';

  @override
  String get transactionEditNameRequired => 'Vui lòng nhập tên';

  @override
  String get transactionEditNotesLabel => 'Ghi chú';

  @override
  String get transactionEditCategoryLabel => 'Danh mục';

  @override
  String get transactionEditMerchantLabel => 'Đơn vị giao dịch';

  @override
  String get transactionEditTagsLabel => 'Nhãn';

  @override
  String get transactionEditSaving => 'Đang lưu…';

  @override
  String get transactionsListDeleteTitle => 'Xóa giao dịch';

  @override
  String transactionsListDeleteSingleContent(String name) {
    return 'Bạn có chắc muốn xóa \"$name\" không?';
  }

  @override
  String get transactionsListDeleteMultiTitle => 'Xóa các giao dịch';

  @override
  String get transactionsListDeleteMultiContent =>
      'Bạn có chắc muốn xóa các giao dịch đã chọn không?';

  @override
  String get transactionsListEmpty => 'Không có giao dịch';

  @override
  String get transactionsListAuthFailed =>
      'Xác thực thất bại: Vui lòng đăng nhập lại';

  @override
  String get transactionsListNoTransactionsYet => 'Chưa có giao dịch';

  @override
  String get transactionsListEmptyAddFirst =>
      'Nhấn + để thêm giao dịch đầu tiên';

  @override
  String get transactionsListNoCategoryMatch =>
      'Không có giao dịch thuộc danh mục này';

  @override
  String get transactionsListRetry => 'Thử lại';

  @override
  String get transactionsListDeletedSuccess => 'Đã xóa giao dịch';

  @override
  String get transactionsListSingleDeleteFailed => 'Không thể xóa giao dịch';

  @override
  String transactionsListDeletedMulti(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xóa $count giao dịch',
      one: 'Đã xóa $count giao dịch',
    );
    return '$_temp0';
  }

  @override
  String get transactionsListDeleteFailed => 'Không thể xóa các giao dịch';

  @override
  String get transactionsListDeleteNoToken =>
      'Không thể xóa: Không có mã truy cập';

  @override
  String get transactionsListUndoTitle => 'Hoàn tác giao dịch';

  @override
  String get transactionsListUndoRemovePending => 'Xóa giao dịch đang chờ này?';

  @override
  String get transactionsListUndoRestoreConfirm => 'Khôi phục giao dịch này?';

  @override
  String get transactionsListUndoPendingRemoved => 'Đã xóa giao dịch đang chờ';

  @override
  String get transactionsListUndoRestored => 'Đã khôi phục giao dịch';

  @override
  String get transactionsListUndoFailed => 'Không thể hoàn tác giao dịch';

  @override
  String get settingsSectionDisplay => 'Hiển thị';

  @override
  String get settingsSectionConnection => 'Kết nối';

  @override
  String get settingsSectionDataManagement => 'Quản lý dữ liệu';

  @override
  String get settingsSectionSecurity => 'Bảo mật';

  @override
  String get settingsSectionDangerZone => 'Thao tác nguy hiểm';

  @override
  String get settingsThemeLabel => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsProxyHeadersLabel => 'Header proxy tùy chỉnh';

  @override
  String get settingsPrivacyHideAmountsLabel => 'Ẩn số tiền';

  @override
  String get settingsPrivacyHideAmountsContent =>
      'Che các giá trị tiền tệ trong toàn bộ ứng dụng';

  @override
  String get settingsBiometricLabel => 'Khóa sinh trắc học';

  @override
  String get settingsBiometricEnable => 'Bật khóa sinh trắc học?';

  @override
  String get settingsBiometricEnableContent =>
      'Yêu cầu xác thực sinh trắc học khi quay lại ứng dụng.';

  @override
  String get settingsCheckForUpdates => 'Kiểm tra cập nhật';

  @override
  String get settingsUpdateAvailableTitle => 'Có bản cập nhật';

  @override
  String settingsUpdateAvailableContent(String version) {
    return 'Đã có phiên bản $version. Cập nhật ngay?';
  }

  @override
  String get settingsUpdateNewerVersionFallback => 'phiên bản mới hơn';

  @override
  String get settingsUpdateNow => 'Cập nhật ngay';

  @override
  String get settingsNoUpdateAvailable =>
      'Bạn đang sử dụng phiên bản mới nhất.';

  @override
  String get settingsUpdateError => 'Không thể kiểm tra cập nhật.';

  @override
  String get settingsClearDataTitle => 'Xóa toàn bộ dữ liệu';

  @override
  String get settingsClearDataContent =>
      'Thao tác này sẽ xóa toàn bộ dữ liệu được lưu tạm trên thiết bị. Dữ liệu trên máy chủ không bị ảnh hưởng.';

  @override
  String get settingsClearData => 'Xóa dữ liệu';

  @override
  String get settingsClearDataSuccess => 'Đã xóa dữ liệu trên thiết bị';

  @override
  String get settingsDeleteAccountTitle => 'Xóa tài khoản';

  @override
  String get settingsDeleteAccount => 'Xóa tài khoản';

  @override
  String get settingsSignOutTitle => 'Đăng xuất';

  @override
  String get settingsSignOutContent => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String get settingsSignOut => 'Đăng xuất';

  @override
  String get settingsDebugLogs => 'Nhật ký gỡ lỗi';

  @override
  String get ssoOnboardingTitle => 'Liên kết tài khoản';

  @override
  String get ssoOnboardingTabLink => 'Liên kết tài khoản có sẵn';

  @override
  String get ssoOnboardingTabCreate => 'Tạo tài khoản mới';

  @override
  String get ssoOnboardingFirstNameLabel => 'Tên';

  @override
  String get ssoOnboardingLastNameLabel => 'Họ';

  @override
  String get ssoOnboardingLinkButton => 'Liên kết tài khoản';

  @override
  String get ssoOnboardingCreateButton => 'Tạo tài khoản';

  @override
  String get ssoOnboardingAcceptInvitation => 'Chấp nhận lời mời';

  @override
  String get calendarTitle => 'Lịch tài khoản';

  @override
  String get calendarAccountTypeSection => 'Loại tài khoản';

  @override
  String get calendarSegmentAssets => 'Tài sản';

  @override
  String get calendarSegmentLiabilities => 'Khoản nợ';

  @override
  String get calendarSelectAccount => 'Chọn tài khoản';

  @override
  String get calendarMonthlyChange => 'Thay đổi trong tháng';

  @override
  String get calendarNoTransactions => 'Không có giao dịch trong ngày này';

  @override
  String get moreCalendar => 'Lịch tài khoản';

  @override
  String get moreCalendarSubtitle =>
      'Xem thay đổi số dư hằng tháng theo tài khoản';

  @override
  String get moreRecentTransactions => 'Giao dịch gần đây';

  @override
  String get moreRecentTransactionsSubtitle =>
      'Xem giao dịch gần đây trên tất cả tài khoản';

  @override
  String get biometricTitle => 'Ứng dụng đã khóa';

  @override
  String get biometricSubtitle => 'Xác thực để tiếp tục';

  @override
  String get biometricUnlock => 'Mở khóa';

  @override
  String get biometricAuthenticating => 'Đang xác thực…';

  @override
  String get biometricLogOut => 'Đăng xuất';

  @override
  String get backendConfigTitle => 'Cấu hình';

  @override
  String get backendConfigSubtitle => 'Cập nhật URL máy chủ Sure';

  @override
  String get backendConfigExampleUrlsLabel => 'URL ví dụ';

  @override
  String get backendConfigUrlLabel => 'URL máy chủ Sure';

  @override
  String get backendConfigUrlHint => 'https://app.sure.am';

  @override
  String get backendConfigProxyHeadersLabel => 'Header proxy tùy chỉnh';

  @override
  String get backendConfigProxyHeadersSubtitle =>
      'Header tùy chọn cho reverse proxy hoặc cổng xác thực';

  @override
  String backendConfigProxyHeadersCount(int count) {
    return 'Đã cấu hình $count';
  }

  @override
  String get backendConfigTesting => 'Đang kiểm tra…';

  @override
  String get backendConfigTestButton => 'Kiểm tra kết nối';

  @override
  String get backendConfigContinueButton => 'Tiếp tục';

  @override
  String get backendConfigChangeHint =>
      'Bạn có thể thay đổi sau trong phần cài đặt.';

  @override
  String get recentTransactionsTitle => 'Giao dịch gần đây';

  @override
  String get recentTransactionsEmpty => 'Không có giao dịch';

  @override
  String get recentTransactionsDisplayLimit => 'Giới hạn hiển thị';

  @override
  String recentTransactionsShowN(int count) {
    return 'Hiển thị $count';
  }

  @override
  String get recentTransactionsPullToRefresh => 'Kéo để làm mới';

  @override
  String get logViewerTitle => 'Nhật ký gỡ lỗi';

  @override
  String get logViewerFilterAll => 'Tất cả';

  @override
  String get logViewerFilterInfo => 'Thông tin';

  @override
  String get logViewerFilterWarning => 'Cảnh báo';

  @override
  String get logViewerFilterError => 'Lỗi';

  @override
  String get logViewerFilterDebug => 'Gỡ lỗi';

  @override
  String get logViewerAutoScrollEnable => 'Bật cuộn tự động';

  @override
  String get logViewerAutoScrollDisable => 'Tắt cuộn tự động';

  @override
  String get logViewerCopyLogs => 'Sao chép nhật ký';

  @override
  String get logViewerClearLogs => 'Xóa nhật ký';

  @override
  String get logViewerLogsCopied => 'Đã sao chép nhật ký vào bảng nhớ tạm';

  @override
  String get logViewerEmpty => 'Chưa có nhật ký';

  @override
  String get connectivityOffline => 'Bạn đang ngoại tuyến';

  @override
  String connectivityPendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giao dịch đang chờ đồng bộ',
      one: '$count giao dịch đang chờ đồng bộ',
    );
    return '$_temp0';
  }

  @override
  String get connectivitySyncNow => 'Đồng bộ ngay';

  @override
  String get proxyHeadersAddHeader => 'Thêm header';

  @override
  String get proxyHeadersNameLabel => 'Tên header';

  @override
  String get proxyHeadersNameHint => 'X-Auth-Token';

  @override
  String get proxyHeadersValueLabel => 'Giá trị header';

  @override
  String get proxyHeadersRemove => 'Xóa header';

  @override
  String get accountDetailRefreshTooltip => 'Làm mới chi tiết tài khoản';

  @override
  String get accountDetailRecentBalanceHistory => 'Lịch sử số dư gần đây';

  @override
  String get accountDetailTopHoldings => 'Các khoản nắm giữ lớn nhất';

  @override
  String get accountDetailHoldingFallback => 'Khoản nắm giữ';

  @override
  String accountDetailCashChip(String amount) {
    return 'Tiền mặt $amount';
  }

  @override
  String get biometricLockFailedRetry =>
      'Xác thực thất bại. Nhấn Mở khóa để thử lại.';

  @override
  String get settingsBiometricVerifyReason =>
      'Xác thực sinh trắc học để bật khóa ứng dụng';

  @override
  String get settingsBiometricFailed => 'Xác thực sinh trắc học thất bại.';

  @override
  String get settingsUpdateOpenStoreError => 'Không thể mở liên kết cửa hàng';

  @override
  String get settingsClearDataFailed => 'Không thể xóa dữ liệu trên thiết bị.';

  @override
  String get settingsClearDataSuccessDetailed =>
      'Đã xóa dữ liệu trên thiết bị. Kéo để làm mới và đồng bộ từ máy chủ.';

  @override
  String get settingsContactOpenLinkError => 'Không thể mở liên kết';

  @override
  String get settingsResetAccountContent =>
      'Đặt lại tài khoản sẽ xóa tất cả tài khoản tài chính, danh mục, đơn vị giao dịch, nhãn và dữ liệu khác, nhưng vẫn giữ tài khoản người dùng của bạn.\n\nKhông thể hoàn tác thao tác này. Bạn có chắc không?';

  @override
  String get settingsResetAccount => 'Đặt lại tài khoản';

  @override
  String get settingsResetAccountInitiated =>
      'Đã bắt đầu đặt lại tài khoản. Quá trình này có thể mất một lúc.';

  @override
  String get settingsResetAccountFailed => 'Không thể đặt lại tài khoản';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'Xóa tài khoản sẽ xóa vĩnh viễn toàn bộ dữ liệu của bạn và không thể hoàn tác.\n\nBạn có chắc muốn xóa tài khoản không?';

  @override
  String get settingsDeleteAccountFailed => 'Không thể xóa tài khoản';

  @override
  String get settingsProxyHeadersNote =>
      'Ứng dụng gửi các header này cùng yêu cầu API. Các trang SSO trên trình duyệt bên ngoài có thể không nhận được chúng.';

  @override
  String get settingsProxyHeadersSaved => 'Đã lưu header proxy tùy chỉnh';

  @override
  String get settingsProxyHeadersSaveFailed =>
      'Không thể lưu header proxy tùy chỉnh.';

  @override
  String settingsAppVersion(String version) {
    return 'Phiên bản ứng dụng: $version';
  }

  @override
  String get settingsCheckForUpdatesSubtitle =>
      'Kiểm tra xem có phiên bản mới hơn không';

  @override
  String get settingsContactUs => 'Liên hệ với chúng tôi';

  @override
  String get settingsDebugLogsSemantics => 'Mở nhật ký gỡ lỗi';

  @override
  String get settingsDebugLogsSubtitle => 'Xem nhật ký chẩn đoán ứng dụng';

  @override
  String get settingsGroupByAccountType => 'Nhóm theo loại tài khoản';

  @override
  String get settingsGroupByAccountTypeSubtitle =>
      'Nhóm tài khoản theo loại (tiền mã hóa, ngân hàng, v.v.)';

  @override
  String get settingsProxyHeadersTileTitle => 'Header proxy tùy chỉnh';

  @override
  String get settingsProxyHeadersTileSubtitleEmpty =>
      'Header tùy chọn cho reverse proxy hoặc cổng xác thực';

  @override
  String settingsProxyHeadersTileSubtitleCount(int count) {
    return 'Đã cấu hình $count';
  }

  @override
  String get settingsClearDataTileSubtitle =>
      'Xóa tất cả giao dịch và tài khoản được lưu tạm';

  @override
  String get settingsResetAccountTileSubtitle =>
      'Xóa tất cả tài khoản tài chính, danh mục, đơn vị giao dịch và nhãn nhưng giữ tài khoản người dùng';

  @override
  String get settingsDeleteAccountTileSubtitle =>
      'Xóa vĩnh viễn toàn bộ dữ liệu của bạn. Không thể hoàn tác.';

  @override
  String get settingsUserFallback => 'Người dùng';

  @override
  String chatListDeleteMultiContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Xóa $count cuộc trò chuyện? Không thể hoàn tác.',
      one: 'Xóa $count cuộc trò chuyện? Không thể hoàn tác.',
    );
    return '$_temp0';
  }

  @override
  String get chatListDeletedSuccess => 'Đã xóa các cuộc trò chuyện';

  @override
  String get chatListDeleteFailed => 'Không thể xóa các cuộc trò chuyện';

  @override
  String get chatListIncomplete =>
      'Có thể thiếu một số cuộc trò chuyện vì danh sách chưa tải xong.';

  @override
  String get chatListError => 'Không thể tải các cuộc trò chuyện';

  @override
  String get chatListJustNow => 'Vừa xong';

  @override
  String chatListDeleteSingleContent(String title) {
    return 'Bạn có chắc muốn xóa \"$title\" không?';
  }

  @override
  String get loginSignUpOpenError => 'Không thể mở trang đăng ký';

  @override
  String get loginApiKeyDialogTitle => 'Đăng nhập bằng khóa API';

  @override
  String get loginApiKeyDialogBody => 'Nhập khóa API của bạn để đăng nhập.';

  @override
  String get loginApiKeyInvalid => 'Khóa API không hợp lệ';

  @override
  String get loginApiKeySignIn => 'Đăng nhập';

  @override
  String get loginDemoOrSignUpPrefix => 'Tài khoản dùng thử hoặc ';

  @override
  String get loginSignUpLink => 'Đăng ký';

  @override
  String get loginSignUpSuffix => '!';

  @override
  String get loginMfaInfo =>
      'Xác thực hai yếu tố đã được bật. Vui lòng nhập mã.';

  @override
  String get loginMfaCodeRequired => 'Vui lòng nhập mã xác thực';

  @override
  String get loginOrDivider => 'hoặc';

  @override
  String get loginServerUrlHeading => 'URL máy chủ Sure:';

  @override
  String get loginApiKeyLoginButton => 'Đăng nhập bằng khóa API';

  @override
  String get loginBackendSettingsTooltip => 'Cài đặt máy chủ';

  @override
  String get transactionEditSessionExpired =>
      'Phiên đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get transactionEditUpdated => 'Đã cập nhật giao dịch';

  @override
  String get transactionEditUpdateFailed => 'Không thể cập nhật giao dịch';

  @override
  String transactionEditNameMaxLength(int max) {
    return 'Tên không được vượt quá $max ký tự';
  }

  @override
  String get transactionEditNameInvalidChars =>
      'Tên chứa ký tự không được hỗ trợ';

  @override
  String transactionEditNotesMaxLength(int max) {
    return 'Ghi chú không được vượt quá $max ký tự';
  }

  @override
  String get transactionEditNotesInvalidChars =>
      'Ghi chú chứa ký tự không được hỗ trợ';

  @override
  String get transactionEditNoCategory => 'Không có danh mục';

  @override
  String get transactionEditCurrentCategory => 'Danh mục hiện tại';

  @override
  String get transactionEditNoMerchant => 'Không có đơn vị giao dịch';

  @override
  String get transactionEditCurrentMerchant => 'Đơn vị giao dịch hiện tại';

  @override
  String get transactionEditNoTags => 'Không có nhãn';

  @override
  String get transactionEditUnknownTag => 'Nhãn không xác định';

  @override
  String get transactionEditSyncedOnly =>
      'Chỉ có thể sửa giao dịch đã đồng bộ trên thiết bị di động.';

  @override
  String get transactionEditCategoryHelper => 'Chọn danh mục thay thế';

  @override
  String get transactionEditMerchantHelper => 'Chọn đơn vị giao dịch thay thế';

  @override
  String get transactionFormSessionExpired =>
      'Phiên đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get transactionFormAmountRequiredPrompt => 'Vui lòng nhập số tiền';

  @override
  String get transactionFormAmountInvalidNumber => 'Vui lòng nhập số hợp lệ';

  @override
  String get transactionFormAmountTooSmall => 'Số tiền phải lớn hơn 0';

  @override
  String get transactionFormCreateSuccessOnline => 'Đã tạo giao dịch';

  @override
  String get transactionFormCreateSuccessOffline =>
      'Đã lưu giao dịch (sẽ đồng bộ khi có kết nối mạng)';

  @override
  String get transactionFormCreateFailed => 'Không thể tạo giao dịch';

  @override
  String transactionFormGenericError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get transactionFormLess => 'Thu gọn';

  @override
  String get transactionFormMore => 'Thêm';

  @override
  String get transactionFormDateHelper => 'Tùy chọn (mặc định: hôm nay)';

  @override
  String get transactionFormNameHelper => 'Tùy chọn (mặc định: SureApp)';

  @override
  String get transactionFormCategoryLoading => 'Đang tải danh mục…';

  @override
  String get transactionFormCategoryHelper => 'Tùy chọn';

  @override
  String get transactionFormNoCategory => 'Không có danh mục';

  @override
  String get transactionFormCreateButton => 'Tạo giao dịch';

  @override
  String get transactionFormAmountHelper => 'Bắt buộc';

  @override
  String get logViewerClearConfirm =>
      'Bạn có chắc muốn xóa toàn bộ nhật ký không?';

  @override
  String get logViewerClear => 'Xóa';

  @override
  String get chatConversationEditTitle => 'Sửa tiêu đề';

  @override
  String get chatConversationTitleLabel => 'Tiêu đề cuộc trò chuyện';

  @override
  String get chatConversationRefreshTooltip => 'Làm mới';

  @override
  String get chatConversationLoadError => 'Không thể tải cuộc trò chuyện';

  @override
  String get navEnableAiChatTitle => 'Bật trò chuyện AI?';

  @override
  String get navEnableAiChatContent =>
      'Trò chuyện AI hiện đang tắt trong cài đặt tài khoản. Bạn có muốn bật ngay không?';

  @override
  String get navEnableAiChatNotNow => 'Để sau';

  @override
  String get navEnableAiChatConfirm => 'Bật AI';

  @override
  String get navEnableAiChatFailed => 'Hiện không thể bật AI.';

  @override
  String get transactionsListEditTooltip => 'Sửa giao dịch';

  @override
  String get connectivitySignInToSync =>
      'Vui lòng đăng nhập để đồng bộ giao dịch';

  @override
  String get connectivitySyncSuccess => 'Đã đồng bộ giao dịch';

  @override
  String get connectivitySyncFailed =>
      'Không thể đồng bộ giao dịch. Vui lòng thử lại.';

  @override
  String get connectivityAuthFailed => 'Không thể xác thực. Vui lòng thử lại.';

  @override
  String ssoOnboardingSignedInAs(String email) {
    return 'Đã đăng nhập bằng $email';
  }

  @override
  String get ssoOnboardingGoogleVerified => 'Đã xác minh tài khoản Google';

  @override
  String get ssoOnboardingLinkCredentialsNote =>
      'Nhập thông tin tài khoản hiện có để liên kết với tính năng đăng nhập bằng Google.';

  @override
  String get ssoOnboardingPendingInvitationNote =>
      'Bạn có lời mời đang chờ. Chấp nhận để tham gia hộ gia đình hiện có.';

  @override
  String get ssoOnboardingCreateIdentityNote =>
      'Tạo tài khoản mới bằng danh tính Google của bạn.';

  @override
  String get ssoOnboardingFirstNameRequired => 'Vui lòng nhập tên';

  @override
  String get ssoOnboardingLastNameRequired => 'Vui lòng nhập họ';

  @override
  String get backendConfigTimeout =>
      'Kết nối hết thời gian chờ. Vui lòng kiểm tra URL và thử lại.';

  @override
  String get backendConfigSuccess => 'Kết nối thành công!';

  @override
  String backendConfigServerError(int code) {
    return 'Máy chủ phản hồi mã trạng thái $code. Vui lòng kiểm tra đây có phải máy chủ Sure không.';
  }

  @override
  String backendConfigConnectionFailed(String error) {
    return 'Kết nối thất bại: $error';
  }

  @override
  String backendConfigSaveFailed(String error) {
    return 'Không thể lưu URL: $error';
  }

  @override
  String get backendConfigUrlRequired => 'Vui lòng nhập URL máy chủ';

  @override
  String get backendConfigUrlScheme =>
      'URL phải bắt đầu bằng http:// hoặc https://';

  @override
  String get backendConfigUrlInvalid => 'Vui lòng nhập URL hợp lệ';

  @override
  String get backendConfigHeadersHelp =>
      'Ứng dụng gửi các header này cùng yêu cầu API. Các trang SSO trên trình duyệt bên ngoài có thể không nhận được chúng.';

  @override
  String get recentTransactionsUnknownAccount => 'Tài khoản không xác định';

  @override
  String get accountDetailUnavailable =>
      'Chi tiết tài khoản tạm thời không khả dụng';

  @override
  String chatListMinutesAgo(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String chatListHoursAgo(int hours) {
    return '$hours giờ trước';
  }

  @override
  String chatListDaysAgo(int days) {
    return '$days ngày trước';
  }

  @override
  String get chatConversationStartFailed =>
      'Không thể bắt đầu cuộc trò chuyện. Vui lòng thử lại.';

  @override
  String get moreBudgets => 'Ngân sách';

  @override
  String get moreBudgetsSubtitle => 'Chi tiêu dự kiến và thực tế theo danh mục';

  @override
  String get budgetsTitle => 'Ngân sách';

  @override
  String get budgetsPreviousMonth => 'Tháng trước';

  @override
  String get budgetsNextMonth => 'Tháng sau';

  @override
  String get budgetsBudgeted => 'Dự kiến';

  @override
  String get budgetsActual => 'Thực tế';

  @override
  String get budgetsRemaining => 'Còn lại';

  @override
  String get budgetsIncome => 'Thu nhập';

  @override
  String budgetsExpectedIncome(String amount) {
    return 'Dự kiến $amount';
  }

  @override
  String budgetsOfAmount(String amount) {
    return 'trên $amount';
  }

  @override
  String budgetsAmountLeft(String amount) {
    return 'Còn $amount';
  }

  @override
  String budgetsOverBy(String amount) {
    return 'Vượt $amount';
  }

  @override
  String budgetsRolledOver(String amount) {
    return '+$amount chuyển sang';
  }

  @override
  String get budgetsSharedBudget => 'Ngân sách chung';

  @override
  String get budgetsNoLimit => 'Chưa có ngân sách';

  @override
  String get budgetsCategoriesTitle => 'Danh mục';

  @override
  String budgetsFilterOverBudget(int count) {
    return 'Vượt ngân sách ($count)';
  }

  @override
  String get budgetsOverBudget => 'Vượt ngân sách';

  @override
  String get budgetsNearLimit => 'Gần giới hạn';

  @override
  String budgetsBudgetNumber(int number) {
    return 'Ngân sách $number';
  }

  @override
  String budgetsNoBudgetTitle(String month) {
    return 'Chưa có ngân sách cho $month';
  }

  @override
  String get budgetsNoBudgetMessage =>
      'Ngân sách được tạo trên Sure bản web. Mở mục Ngân sách tại đó để thiết lập cho tháng này.';

  @override
  String get budgetsNotSetUpMessage =>
      'Chưa thiết lập giới hạn chi tiêu cho tháng này. Hãy thiết lập trên Sure bản web.';

  @override
  String get budgetsNoCategories =>
      'Chưa có danh mục ngân sách hoặc chi tiêu trong tháng này.';

  @override
  String get budgetsOfflineTitle => 'Bạn đang ngoại tuyến';

  @override
  String get budgetsOfflineMessage =>
      'Kết nối internet để tải ngân sách tháng này.';

  @override
  String get budgetsOfflineCached =>
      'Ngoại tuyến. Đang hiển thị số liệu đã tải trước đó.';

  @override
  String get budgetsRefreshFailed =>
      'Không thể làm mới. Đang hiển thị số liệu đã tải trước đó.';

  @override
  String get budgetsLoadFailed => 'Không thể tải ngân sách';

  @override
  String get budgetsSessionExpired =>
      'Phiên đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String budgetCategoryTransactionsEmpty(String month) {
    return 'Không có giao dịch thuộc danh mục này trong $month.';
  }

  @override
  String get budgetCategoryTransactionsLoadMore => 'Tải thêm';

  @override
  String get budgetCategoryTransactionsLoadFailed => 'Không thể tải giao dịch';

  @override
  String get moreCashFlow => 'Dòng tiền';

  @override
  String get moreCashFlowSubtitle =>
      'Thu nhập, chi tiêu và tiết kiệm theo danh mục';

  @override
  String get cashFlowTitle => 'Dòng tiền';

  @override
  String get cashFlowPeriodCurrentMonth => 'Tháng này';

  @override
  String get cashFlowPeriodLastMonth => 'Tháng trước';

  @override
  String get cashFlowPeriodLast30Days => '30 ngày qua';

  @override
  String get cashFlowPeriodLast90Days => '90 ngày qua';

  @override
  String get cashFlowPeriodCurrentYear => 'Từ đầu năm đến nay';

  @override
  String get cashFlowPeriodLast365Days => '365 ngày qua';

  @override
  String get cashFlowIncome => 'Thu nhập';

  @override
  String get cashFlowExpenses => 'Chi tiêu';

  @override
  String get cashFlowNetSavings => 'Tiết kiệm ròng';

  @override
  String cashFlowSavingsRate(String rate) {
    return 'Tỷ lệ tiết kiệm $rate';
  }

  @override
  String get cashFlowExpensesByCategory => 'Chi tiêu theo danh mục';

  @override
  String get cashFlowIncomeByCategory => 'Thu nhập theo danh mục';

  @override
  String cashFlowShareOfExpenses(String percent) {
    return '$percent chi tiêu';
  }

  @override
  String cashFlowShareOfIncome(String percent) {
    return '$percent thu nhập';
  }

  @override
  String get cashFlowEmpty => 'Không có thu nhập hoặc chi tiêu trong kỳ này';

  @override
  String get cashFlowEmptySubtitle => 'Thử kỳ khác hoặc kéo để làm mới.';

  @override
  String get cashFlowNoExpenses => 'Không có chi tiêu trong kỳ này';

  @override
  String get cashFlowNoIncome => 'Không có thu nhập trong kỳ này';

  @override
  String get cashFlowLoadFailed => 'Không thể tải dòng tiền';

  @override
  String get cashFlowOffline =>
      'Bạn đang ngoại tuyến. Dòng tiền được tính trên máy chủ Sure nên cần có kết nối mạng.';

  @override
  String get cashFlowOutdated => 'Chưa cập nhật';

  @override
  String get cashFlowTransactionsEmpty => 'Không có giao dịch trong kỳ này';

  @override
  String get cashFlowTransactionsLoadFailed => 'Không thể tải giao dịch';

  @override
  String get introTitle => 'Trải nghiệm giới thiệu sắp ra mắt';

  @override
  String get introBody =>
      'Chúng tôi đang xây dựng trải nghiệm giới thiệu đầy đủ hơn để tìm hiểu mục tiêu, cột mốc và nhu cầu hằng ngày của bạn. Trong lúc này, hãy mở mục trò chuyện để trao đổi với Sure và chia sẻ chặng đường tài chính của bạn.';

  @override
  String get navTogglePrivacy => 'Bật hoặc tắt chế độ riêng tư';

  @override
  String get dashboardNetWorth => 'Giá trị tài sản ròng';

  @override
  String get syncPending => 'Đang chờ';

  @override
  String get syncDeleting => 'Đang xóa';

  @override
  String get syncFailed => 'Thất bại';

  @override
  String get syncPendingSemantics => 'Giao dịch đang chờ đồng bộ';

  @override
  String get syncDeletingSemantics => 'Giao dịch đang chờ xóa';

  @override
  String buttonLoading(String label) {
    return '$label, đang tải';
  }

  @override
  String get biometricUnlockReason => 'Mở khóa Sure để tiếp tục';

  @override
  String get accountTypeDepository => 'Tài khoản ngân hàng';

  @override
  String get accountTypeCreditCard => 'Thẻ tín dụng';

  @override
  String get accountTypeInvestment => 'Đầu tư';

  @override
  String get accountTypeLoan => 'Khoản vay';

  @override
  String get accountTypeProperty => 'Bất động sản';

  @override
  String get accountTypeVehicle => 'Phương tiện';

  @override
  String get accountTypeCrypto => 'Tiền mã hóa';

  @override
  String get accountTypeOtherAsset => 'Tài sản khác';

  @override
  String get accountTypeOtherLiability => 'Khoản nợ khác';

  @override
  String get proxyHeaderNameRequired => 'Vui lòng nhập tên header';

  @override
  String get proxyHeaderNameInvalid => 'Vui lòng dùng tên HTTP header hợp lệ';

  @override
  String get proxyHeaderReserved => 'Header này do ứng dụng quản lý';

  @override
  String get proxyHeaderValueRequired => 'Vui lòng nhập giá trị header';

  @override
  String get proxyHeaderValueInvalid => 'Giá trị header chứa ký tự điều khiển';

  @override
  String get updateTitle => 'Có bản cập nhật';

  @override
  String updateBody(
      String appName, String storeVersion, String installedVersion) {
    return 'Đã có $appName $storeVersion — bạn đang dùng $installedVersion.\n\nCó gì mới? Xem ghi chú phát hành trên cửa hàng.';
  }

  @override
  String get updateNow => 'Cập nhật ngay';

  @override
  String get updateLater => 'Để sau';

  @override
  String get errorNetworkUnavailable => 'Không có kết nối mạng';

  @override
  String get errorTimeout => 'Yêu cầu hết thời gian chờ';

  @override
  String get errorInvalidResponse => 'Phản hồi từ máy chủ không hợp lệ';

  @override
  String get errorUnexpected => 'Đã xảy ra lỗi không mong đợi';

  @override
  String get errorLogin => 'Đăng nhập thất bại';

  @override
  String get errorSignup => 'Đăng ký thất bại';

  @override
  String get errorTokenRefresh => 'Không thể làm mới mã truy cập';

  @override
  String errorLoginStatus(String code) {
    return 'Đăng nhập thất bại (mã trạng thái $code)';
  }

  @override
  String get errorSsoLogin => 'Đăng nhập SSO thất bại';

  @override
  String get errorSsoCallback => 'Phản hồi callback SSO không hợp lệ';

  @override
  String get errorTokenExchange => 'Không thể trao đổi mã truy cập';

  @override
  String get errorAuthorizationCode => 'Không thể trao đổi mã ủy quyền';

  @override
  String get errorAccountLink => 'Không thể liên kết tài khoản';

  @override
  String get errorAccountCreate => 'Không thể tạo tài khoản';

  @override
  String get errorNetwork => 'Lỗi mạng';

  @override
  String errorNetworkDetails(String error) {
    return 'Lỗi mạng: $error';
  }

  @override
  String get errorInvalidMfa => 'Mã xác thực không hợp lệ. Vui lòng thử lại.';

  @override
  String get errorConnectRetry =>
      'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get errorBrowser => 'Không thể mở trình duyệt để đăng nhập.';

  @override
  String get errorStartSignIn =>
      'Không thể bắt đầu đăng nhập. Vui lòng thử lại.';

  @override
  String get errorSignInRetry => 'Đăng nhập thất bại. Vui lòng thử lại.';

  @override
  String get errorNoSsoSession =>
      'Không có phiên SSO đang chờ. Vui lòng đăng nhập lại.';

  @override
  String get errorAccountLinkRetry =>
      'Không thể liên kết tài khoản. Vui lòng thử lại.';

  @override
  String get errorAccountCreateRetry =>
      'Không thể tạo tài khoản. Vui lòng thử lại.';

  @override
  String get errorRetry => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get errorChatCreate => 'Không thể tạo cuộc trò chuyện';

  @override
  String get errorChatSend => 'Không thể gửi tin nhắn';

  @override
  String get errorChatUpdate => 'Không thể cập nhật cuộc trò chuyện';

  @override
  String get errorChatRetry => 'Không thể gửi lại tin nhắn';

  @override
  String get errorChatNotFound => 'Không tìm thấy cuộc trò chuyện';

  @override
  String get errorAiDisabled => 'Tính năng AI chưa được bật';

  @override
  String get errorAssistantTimeout =>
      'Trợ lý phản hồi quá lâu. Vui lòng thử lại.';

  @override
  String get errorAccountsOffline =>
      'Bạn đang ngoại tuyến. Vui lòng kết nối internet để tải tài khoản.';

  @override
  String get errorNetworkRetry =>
      'Lỗi mạng. Vui lòng kiểm tra kết nối internet và thử lại.';

  @override
  String get errorTimeoutRetry =>
      'Yêu cầu hết thời gian chờ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get errorServerRetry =>
      'Lỗi phản hồi từ máy chủ. Vui lòng thử lại sau.';

  @override
  String get errorSecureConnection =>
      'Lỗi kết nối bảo mật. Vui lòng kiểm tra kết nối internet và thử lại.';

  @override
  String get biometricHint => 'Xác minh danh tính';

  @override
  String get biometricNotRecognized => 'Không nhận diện được. Hãy thử lại.';

  @override
  String get biometricSuccess => 'Thành công';

  @override
  String get biometricRequired => 'Yêu cầu sinh trắc học';

  @override
  String get biometricCredentialsRequired => 'Yêu cầu mã khóa thiết bị';

  @override
  String get biometricGoToSettings => 'Mở cài đặt';

  @override
  String get biometricAndroidSetup =>
      'Thiết bị chưa thiết lập xác thực sinh trắc học. Mở Cài đặt > Bảo mật để thêm xác thực sinh trắc học.';

  @override
  String get biometricAuthenticationRequired => 'Yêu cầu xác thực';

  @override
  String get biometricLockout =>
      'Xác thực sinh trắc học đã bị tắt. Hãy khóa rồi mở khóa màn hình để bật lại.';

  @override
  String get biometricIosSetup =>
      'Thiết bị chưa thiết lập xác thực sinh trắc học. Vui lòng bật Touch ID hoặc Face ID trên điện thoại.';

  @override
  String get biometricOk => 'Đồng ý';

  @override
  String get accountTransactions => 'Giao dịch';

  @override
  String get chatThinking => 'Đang suy nghĩ';

  @override
  String get errorUploadTransaction =>
      'Không thể tải giao dịch lên. Giao dịch sẽ đồng bộ khi có kết nối mạng.';

  @override
  String get errorEditOffline =>
      'Hãy kết nối internet trước khi sửa giao dịch đã đồng bộ.';

  @override
  String get errorSyncOffline => 'Không thể đồng bộ khi ngoại tuyến';

  @override
  String get errorSyncInProgress => 'Đang đồng bộ';

  @override
  String get errorNoFields => 'Không có trường nào cần cập nhật';

  @override
  String errorDeleteTransactionsCount(String count) {
    return 'Không thể xóa $count giao dịch';
  }

  @override
  String errorDeleteTransactionDetails(String error) {
    return 'Không thể xóa giao dịch: $error';
  }

  @override
  String get transactionFormDefaultNotes =>
      'Giao dịch này được tạo qua ứng dụng di động.';
}
