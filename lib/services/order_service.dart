import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ShopImageService _imageService = ShopImageService();

  // ============ PAYMENT METHODS ============

  /// Get payment methods for a shop
  Future<List<Map<String, dynamic>>> getShopPaymentMethods(
    String shopId,
  ) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_payment_methods')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('display_order');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetShopPaymentMethods Error: $e');
      return [];
    }
  }

  /// Add payment method for shop owner
  Future<Map<String, dynamic>> addPaymentMethod({
    required String shopId,
    required String methodType,
    String? accountName,
    String? accountNumber,
    File? qrCodeFile,
    int displayOrder = 0,
  }) async {
    try {
      String? qrCodeUrl;
      if (qrCodeFile != null) {
        qrCodeUrl = await _imageService.uploadImage(
          file: qrCodeFile,
          shopId: shopId,
          imageType: 'payment_qr',
        );
      }

      final response = await _supabase
          .schema('munajat_app')
          .from('shop_payment_methods')
          .insert({
            'shop_id': shopId,
            'method_type': methodType,
            'account_name': accountName,
            'account_number': accountNumber,
            'qr_code_url': qrCodeUrl,
            'display_order': displayOrder,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('AddPaymentMethod Error: $e');
      rethrow;
    }
  }

  /// Update payment method
  Future<void> updatePaymentMethod({
    required String methodId,
    String? methodType,
    String? accountName,
    String? accountNumber,
    String? qrCodeUrl,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (methodType != null) updates['method_type'] = methodType;
    if (accountName != null) updates['account_name'] = accountName;
    if (accountNumber != null) updates['account_number'] = accountNumber;
    if (qrCodeUrl != null) updates['qr_code_url'] = qrCodeUrl;
    if (isActive != null) updates['is_active'] = isActive;
    if (updates.isEmpty) return;

    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_payment_methods')
          .update(updates)
          .eq('id', methodId);
    } catch (e) {
      debugPrint('UpdatePaymentMethod Error: $e');
      rethrow;
    }
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String methodId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_payment_methods')
          .delete()
          .eq('id', methodId);
    } catch (e) {
      debugPrint('DeletePaymentMethod Error: $e');
      rethrow;
    }
  }

  // ============ ORDERS ============

  /// Create a new order
  Future<Map<String, dynamic>> createOrder({
    required String shopId,
    required List<Map<String, dynamic>>
    items, // {menu_item_id, item_name, item_price, quantity, notes}
    required double totalAmount,
    String? notes,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? paymentScreenshotUrl,
    String orderType = 'in_app',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Create order
      final order = await _supabase
          .schema('munajat_app')
          .from('orders')
          .insert({
            'shop_id': shopId,
            'customer_id': userId,
            'status': paymentScreenshotUrl != null
                ? 'payment_uploaded'
                : 'pending_payment',
            'order_type': orderType,
            'total_amount': totalAmount,
            'notes': notes,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'delivery_address': deliveryAddress,
            'payment_screenshot_url': paymentScreenshotUrl,
          })
          .select()
          .single();

      // Create order items
      final orderId = order['id'];
      for (final item in items) {
        await _supabase.schema('munajat_app').from('order_items').insert({
          'order_id': orderId,
          'menu_item_id': item['menu_item_id'],
          'item_name': item['item_name'],
          'item_price': item['item_price'],
          'quantity': item['quantity'] ?? 1,
          'notes': item['notes'],
        });
      }

      return order;
    } catch (e) {
      debugPrint('CreateOrder Error: $e');
      rethrow;
    }
  }

  /// Upload payment screenshot
  Future<void> uploadPaymentScreenshot({
    required String orderId,
    required File screenshotFile,
  }) async {
    try {
      // Upload to storage
      final url = await _imageService.uploadImage(
        file: screenshotFile,
        shopId: orderId, // Using orderId as folder
        imageType: 'payment_proof',
      );

      // Update order with screenshot URL
      await _supabase
          .schema('munajat_app')
          .from('orders')
          .update({'payment_screenshot_url': url, 'status': 'payment_uploaded'})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('UploadPaymentScreenshot Error: $e');
      rethrow;
    }
  }

  /// Get customer's orders
  Future<List<Map<String, dynamic>>> getCustomerOrders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .schema('munajat_app')
          .from('orders')
          .select('*, shops:shop_id(name, address)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetCustomerOrders Error: $e');
      return [];
    }
  }

  /// Stream customer's orders
  Stream<List<Map<String, dynamic>>> streamCustomerOrders() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _supabase
        .schema('munajat_app')
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .map((event) {
          // Note: realtime stream payload typically doesn't include joined tables (shops)
          // We might need to fetch shop info separately or trust the UI to handle lightweight display
          // For now returning raw events, UI can fetch shops if needed or we rely on what we have.
          // BUT - stream returns List<Map<String, dynamic>>, which needs to be usable.
          // The issue is stream events don't support .select() joins.
          // Strategy: Return the stream, and let UI handle basic info.
          // Better Strategy: Fetch full shop data on snapshots? Too expensive.
          // Since getCustomerOrders() does the join, using stream for *status updates* might be tricky if we need detailed shop names.
          // Actually, let's keep it simple: stream list of orders. The UI is just a list.
          // If shop info is missing in stream, we might lose shop names on updates.
          // Let's rely on cached data or manual refresh if needed, OR just accept that stream provides core order data.
          // Wait, we can't join in stream.
          // Option: Stream just IDs/Status, and merge with existing list? Too complex for this MVP.
          // Alternative: The `OrderHistoryScreen` needs `shops` object.
          // If we stream raw orders, `shops` will be null.
          // We can fetch shop info for each order in the stream map?
          // That would make N requests per stream update. Not great.
          // Let's assume we can live with basic info or try to fetch essential lookups.
          // For now, let's return the stream and see.
          // Correction: Supabase Realtime *does not* support joins.
          // We will use stream for triggering updates or basic lists.
          // Actually, let's keep getCustomerOrders() for initial load, and maybe stream for notifications?
          // The user requested "Realtime".
          // If we replace Future with Stream, we lose Shop Name unless we fetch it.
          // Hack: Fetch shop names for the *ids* in the stream?
          // Just implement the stream method for now and we will handle the UI logic in the screen.
          return List<Map<String, dynamic>>.from(event);
        });
  }

  /// Get live orders stream for a shop
  Stream<List<Map<String, dynamic>>> streamShopOrders(String shopId) {
    return _supabase
        .schema('munajat_app')
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('shop_id', shopId)
        .order('created_at', ascending: false)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  /// Get orders for a shop (for shop owners)
  Future<List<Map<String, dynamic>>> getShopOrders(
    String shopId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .schema('munajat_app')
          .from('orders')
          .select() // Removed profiles join as customer info is now in orders table
          .eq('shop_id', shopId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetShopOrders Error: $e');
      return [];
    }
  }

  /// Get order items
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('order_items')
          .select()
          .eq('order_id', orderId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GetOrderItems Error: $e');
      return [];
    }
  }

  /// Get single order with items
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final order = await _supabase
          .schema('munajat_app')
          .from('orders')
          .select('*, shops:shop_id(name, address, contact_phone)')
          .eq('id', orderId)
          .single();

      final items = await getOrderItems(orderId);
      order['items'] = items;
      return order;
    } catch (e) {
      debugPrint('GetOrderDetails Error: $e');
      return null;
    }
  }

  /// Update order status (for shop owners)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('UpdateOrderStatus Error: $e');
      rethrow;
    }
  }

  /// Confirm payment (for shop owners)
  Future<void> confirmPayment(String orderId) async {
    await updateOrderStatus(orderId, 'payment_confirmed');
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  /// Get order status display text
  static String getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Awaiting Payment';
      case 'payment_uploaded':
        return 'Payment Uploaded';
      case 'payment_confirmed':
        return 'Payment Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get status color
  static int getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return 0xFFFF9800; // Orange
      case 'payment_uploaded':
        return 0xFF2196F3; // Blue
      case 'payment_confirmed':
        return 0xFF4CAF50; // Green
      case 'preparing':
        return 0xFF9C27B0; // Purple
      case 'ready':
        return 0xFF00BCD4; // Cyan
      case 'completed':
        return 0xFF8BC34A; // Light Green
      case 'cancelled':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Get dashboard statistics for shop owner
  Future<Map<String, dynamic>> getOwnerDashboardStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return {'totalOrders': 0, 'totalRevenue': 0.0, 'views': 0};
    }

    try {
      // 1. Get IDs of all shops owned by this user
      final shopsResponse = await _supabase
          .schema('munajat_app')
          .from('shops')
          .select('id')
          .eq('owner_id', userId);

      final shopIds = List<Map<String, dynamic>>.from(
        shopsResponse,
      ).map((s) => s['id'] as String).toList();

      if (shopIds.isEmpty) {
        return {'totalOrders': 0, 'totalRevenue': 0.0, 'views': 0};
      }

      // 2. Get all orders for these shops
      final ordersResponse = await _supabase
          .schema('munajat_app')
          .from('orders')
          .select('total_amount, status')
          .filter('shop_id', 'in', shopIds);

      final orders = List<Map<String, dynamic>>.from(ordersResponse);

      double revenue = 0;
      int count = 0;

      for (var order in orders) {
        if (order['status'] != 'cancelled') {
          revenue += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
          count++;
        }
      }

      return {
        'totalOrders': count,
        'totalRevenue': revenue,
        'views': 0, // Views are not currently tracked in the database
      };
    } catch (e) {
      debugPrint('GetOwnerDashboardStats Error: $e');
      return {'totalOrders': 0, 'totalRevenue': 0.0, 'views': 0};
    }
  }
}
