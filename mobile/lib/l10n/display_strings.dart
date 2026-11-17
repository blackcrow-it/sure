import 'app_localizations.dart';

/// Presentation of protocol values and legacy service errors. Unknown server
/// messages and account types are preserved; they may contain user data.
extension DisplayStrings on AppLocalizations {
  String accountType(String type) => switch (type) {
        'depository' => accountTypeDepository,
        'credit_card' => accountTypeCreditCard,
        'investment' => accountTypeInvestment,
        'loan' => accountTypeLoan,
        'property' => accountTypeProperty,
        'vehicle' => accountTypeVehicle,
        'crypto' => accountTypeCrypto,
        'other_asset' => accountTypeOtherAsset,
        'other_liability' => accountTypeOtherLiability,
        _ => type,
      };

  String displayError(String message) {
    if (message.startsWith('Network error: ')) {
      return errorNetworkDetails(message.substring('Network error: '.length));
    }
    final loginStatus =
        RegExp(r'^Login failed \(status (\d+)\)$').firstMatch(message);
    if (loginStatus != null) return errorLoginStatus(loginStatus.group(1)!);
    final deleteCount =
        RegExp(r'^Failed to delete (\d+) transactions$').firstMatch(message);
    if (deleteCount != null) {
      return errorDeleteTransactionsCount(deleteCount.group(1)!);
    }
    if (message.startsWith('Failed to delete transaction: ')) {
      return errorDeleteTransactionDetails(
          message.substring('Failed to delete transaction: '.length));
    }
    return switch (message) {
      'Failed to upload transaction. It will sync when online.' =>
        errorUploadTransaction,
      'Connect to the internet before editing synced transactions.' =>
        errorEditOffline,
      'Only synced transactions can be edited from mobile.' =>
        transactionEditSyncedOnly,
      'Cannot sync while offline' => errorSyncOffline,
      'Sync already in progress' => errorSyncInProgress,
      'Failed to sync from server' ||
      'Failed to sync accounts' =>
        connectivitySyncFailed,
      'Failed to fetch transactions' => budgetCategoryTransactionsLoadFailed,
      'No fields to update' => errorNoFields,
      'Failed to update transaction' => transactionEditUpdateFailed,
      'Failed to delete transaction' => transactionsListSingleDeleteFailed,
      'Failed to delete transactions' => transactionsListDeleteFailed,
      'Failed to undo transaction' => transactionsListUndoFailed,
      'Header name is required' => proxyHeaderNameRequired,
      'Use a valid HTTP header name' => proxyHeaderNameInvalid,
      'This header is managed by the app' => proxyHeaderReserved,
      'Header value is required' => proxyHeaderValueRequired,
      'Header value contains control characters' => proxyHeaderValueInvalid,
      'Network unavailable' => errorNetworkUnavailable,
      'Request timed out' => errorTimeout,
      'Invalid response from server' => errorInvalidResponse,
      'An unexpected error occurred' => errorUnexpected,
      'Login failed' => errorLogin,
      'Signup failed' => errorSignup,
      'Token refresh failed' => errorTokenRefresh,
      'Invalid API key' => loginApiKeyInvalid,
      'SSO login failed' => errorSsoLogin,
      'Invalid SSO callback response' => errorSsoCallback,
      'Token exchange failed' => errorTokenExchange,
      'Failed to exchange authorization code' => errorAuthorizationCode,
      'Account linking failed' || 'Failed to link account' => errorAccountLink,
      'Account creation failed' ||
      'Failed to create account' =>
        errorAccountCreate,
      'Failed to enable AI' => navEnableAiChatFailed,
      'Network error' => errorNetwork,
      'Invalid authentication code. Please try again.' => errorInvalidMfa,
      'Unable to connect. Please check your network and try again.' =>
        errorConnectRetry,
      'Unable to open browser for sign-in.' => errorBrowser,
      'Unable to start sign-in. Please try again.' => errorStartSignIn,
      'Sign-in failed. Please try again.' => errorSignInRetry,
      'No pending SSO session. Please try signing in again.' =>
        errorNoSsoSession,
      'Failed to link account. Please try again.' => errorAccountLinkRetry,
      'Failed to create account. Please try again.' => errorAccountCreateRetry,
      'Session expired. Please login again.' ||
      'unauthorized' =>
        transactionEditSessionExpired,
      'Something went wrong. Please try again.' => errorRetry,
      'Failed to fetch chats' => chatListError,
      'Failed to fetch chat' => chatConversationLoadError,
      'Failed to create chat' => errorChatCreate,
      'Failed to send message' => errorChatSend,
      'Failed to update chat' => errorChatUpdate,
      'Failed to retry message' => errorChatRetry,
      'Failed to delete chat' ||
      'Failed to delete chats' =>
        chatListDeleteFailed,
      'Chat not found' || 'not_found' => errorChatNotFound,
      'AI features not enabled' || 'feature_disabled' => errorAiDisabled,
      'The assistant took too long to respond. Please try again.' =>
        errorAssistantTimeout,
      'Failed to fetch accounts' => dashboardErrorLoadingAccounts,
      'You are offline. Please connect to the internet to load accounts.' =>
        errorAccountsOffline,
      'Network error. Please check your internet connection and try again.' =>
        errorNetworkRetry,
      'Request timed out. Please check your connection and try again.' =>
        errorTimeoutRetry,
      'Server response error. Please try again later.' => errorServerRetry,
      'Secure connection error. Please check your internet connection and try again.' =>
        errorSecureConnection,
      'Failed to reset account' => settingsResetAccountFailed,
      'Failed to delete account' => settingsDeleteAccountFailed,
      _ => message,
    };
  }
}
