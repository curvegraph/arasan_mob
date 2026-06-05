import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/order_api_service.dart';

class UserShipmentTrackingScreen extends StatefulWidget {
  final String orderId;

  const UserShipmentTrackingScreen({super.key, required this.orderId});

  @override
  State<UserShipmentTrackingScreen> createState() =>
      _UserShipmentTrackingScreenState();
}

class _UserShipmentTrackingScreenState
    extends State<UserShipmentTrackingScreen> {
  final OrderApiService _orderApiService = OrderApiService();
  TrackingInfo? _trackingInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final info = await _orderApiService.trackOrder(widget.orderId);
      setState(() {
        _trackingInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load tracking info';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipment Tracking')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTracking,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildTrackingContent(),
    );
  }

  Widget _buildTrackingContent() {
    final info = _trackingInfo!;
    return RefreshIndicator(
      onRefresh: _loadTracking,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${info.orderNumber}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Status: ${info.currentStatus}',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  if (info.currentStatusDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(info.currentStatusDescription!,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textTertiary)),
                  ],
                  if (info.courierName != null) ...[
                    const SizedBox(height: 8),
                    Text('Courier: ${info.courierName}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                  if (info.awb != null) ...[
                    const SizedBox(height: 4),
                    Text('AWB: ${info.awb}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tracking timeline
          if (info.trackingHistory.isNotEmpty) ...[
            const Text('Tracking History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...info.trackingHistory.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.activity,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${event.date.day}/${event.date.month}/${event.date.year} ${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No tracking updates yet',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }
}
