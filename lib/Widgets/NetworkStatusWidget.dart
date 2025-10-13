import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/NetworkProvider.dart';
import '../core/const/custamSnackBar.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showNetworkMessages;

  const NetworkStatusWidget({
    Key? key,
    required this.child,
    this.showNetworkMessages = true,
  }) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _wasOnline = true;
  bool _hasShownOfflineMessage = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, _) {
        // Show snackbar when network status changes
        if (widget.showNetworkMessages) {
          _handleNetworkStatusChange(context, networkProvider);
        }
        
        return widget.child;
      },
    );
  }

  void _handleNetworkStatusChange(BuildContext context, NetworkProvider networkProvider) {
    final bool isCurrentlyOnline = networkProvider.isOnline;
    
    // Network went offline
    if (!isCurrentlyOnline && _wasOnline && !_hasShownOfflineMessage) {
      _hasShownOfflineMessage = true;
      CustomSnackBar.showWarning(
        context,
        'No internet connection. Some features may not work.',
      );
    }
    
    // Network came back online
    if (isCurrentlyOnline && !_wasOnline) {
      _hasShownOfflineMessage = false;
      CustomSnackBar.showSuccess(
        context,
        'Internet connection restored!',
      );
    }
    
    _wasOnline = isCurrentlyOnline;
  }

}

class NetworkAwareScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool showNetworkMessages;

  const NetworkAwareScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.showNetworkMessages = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NetworkStatusWidget(
      showNetworkMessages: showNetworkMessages,
      child: Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

class NetworkErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const NetworkErrorDialog({
    Key? key,
    this.title = 'Network Error',
    required this.message,
    this.onRetry,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
      ],
    );
  }
}

class NetworkAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool requireInternet;
  final String? offlineMessage;

  const NetworkAwareButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.requireInternet = true,
    this.offlineMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, _) {
        final bool canExecute = !requireInternet || networkProvider.isOnline;
        
        return Opacity(
          opacity: canExecute ? 1.0 : 0.6,
          child: AbsorbPointer(
            absorbing: !canExecute,
            child: Tooltip(
              message: !canExecute 
                  ? (offlineMessage ?? 'Internet connection required')
                  : '',
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// Utility class for network-related snackbars
class NetworkSnackBar {
  static void showNetworkError(BuildContext context, String message) {
    CustomSnackBar.showFailure(context, message);
  }

  static void showNetworkSuccess(BuildContext context, String message) {
    CustomSnackBar.showSuccess(context, message);
  }

  static void showNetworkWarning(BuildContext context, String message) {
    CustomSnackBar.showWarning(context, message);
  }
}
