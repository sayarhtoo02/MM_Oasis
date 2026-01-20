import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/order_service.dart';
import 'package:munajat_e_maqbool_app/services/auth_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_menu_screen.dart';

class CartScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
  final List<CartItem> cartItems;
  final Function(List<CartItem>) onCartUpdated;

  const CartScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.cartItems,
    required this.onCartUpdated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final ShopImageService _imageService = ShopImageService();

  late List<CartItem> _items;
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = false;
  File? _paymentScreenshot;

  // Order info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
    _loadPaymentMethods();
    _loadUserInfo();
  }

  Future<void> _loadPaymentMethods() async {
    final methods = await _orderService.getShopPaymentMethods(widget.shopId);
    if (mounted) {
      setState(() => _paymentMethods = methods);
    }
  }

  void _loadUserInfo() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['display_name'] ?? '';
      _phoneController.text = user.phone ?? '';
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
    });
    widget.onCartUpdated(_items);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    widget.onCartUpdated(_items);

    if (_items.isEmpty) {
      Navigator.pop(context);
    }
  }

  double get _total {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) return;

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and phone number'),
        ),
      );
      return;
    }

    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a payment screenshot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload Screenshot
      String? paymentUrl;
      if (_paymentScreenshot != null) {
        paymentUrl = await _imageService.uploadImage(
          file: _paymentScreenshot!,
          shopId: widget
              .shopId, // Using shopId as folder since we don't have orderId yet
          imageType: 'payment_proof',
        );
      }

      // 2. Prepare Items
      final orderItems = _items
          .map(
            (item) => {
              'menu_item_id': item.id,
              'item_name': item.name,
              'item_price': item.price,
              'quantity': item.quantity,
            },
          )
          .toList();

      // 3. Create Order
      await _orderService.createOrder(
        shopId: widget.shopId,
        items: orderItems,
        totalAmount: _total,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        paymentScreenshotUrl: paymentUrl,
      );

      if (mounted) {
        // Clear cart and go back
        widget.onCartUpdated([]);
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Order placed successfully! Waiting for shop confirmation.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      }
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    final file = await _imageService.pickImageFromGallery();
    if (file != null) {
      setState(() => _paymentScreenshot = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Checkout',
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 1. Cart Items Section
                          Text(
                            'Order Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_items.length, (index) {
                            return _buildCartItem(
                              _items[index],
                              index,
                              isDark,
                              textColor,
                              accentColor,
                            );
                          }),
                          /*
                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                isDark: isDark,
                                borderRadius: 12,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: item.imageUrl != null
                                              ? Image.network(
                                                  item.imageUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Icon(
                                                  Icons.restaurant,
                                                  color: textColor.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                            Text(
                                              'K ${item.price.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Quantity controls
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                            onPressed: () =>
                                                _updateQuantity(index, -1),
                                            color: textColor,
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            onPressed: () =>
                                                _updateQuantity(index, 1),
                                            color: accentColor,
                                          ),
                                        ],
                                      ),
                                      // Delete
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _removeItem(index),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          */
                          const SizedBox(height: 20),

                          // 2. Customer Info
                          Text(
                            'Your Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.note_outlined),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),

                          // 3. Payment Methods
                          Text(
                            'Payment Methods',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_paymentMethods.isEmpty)
                            GlassCard(
                              isDark: isDark,
                              borderRadius: 12,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No payment methods configured. Please contact the shop.',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._paymentMethods.map(
                              (method) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCard(
                                  isDark: isDark,
                                  borderRadius: 12,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _getPaymentIcon(
                                                method['method_type'],
                                              ),
                                              color: accentColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              (method['method_type'] as String)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (method['account_name'] != null)
                                          Text(
                                            'Name: ${method['account_name']}',
                                            style: TextStyle(color: textColor),
                                          ),
                                        if (method['account_number'] != null)
                                          SelectableText(
                                            'Number: ${method['account_number']}',
                                            style: TextStyle(
                                              color: accentColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (method['qr_code_url'] != null) ...[
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              method['qr_code_url'],
                                              height: 150,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // 4. Upload Payment Screenshot
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Please make the payment and upload the screenshot below to place your order.',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Payment Screenshot *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickPaymentScreenshot,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _paymentScreenshot == null
                                      ? Colors.red.withValues(alpha: 0.5)
                                      : accentColor.withValues(alpha: 0.5),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              child: _paymentScreenshot != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Image.file(
                                            _paymentScreenshot!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 48,
                                          color: accentColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to upload screenshot',
                                          style: TextStyle(
                                            color: textColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 100), // Spacing for bottom bar
                        ],
                      ),
                    ),

                    // Bottom Bar
                    GlassCard(
                      borderRadius: 0,
                      isDarkForce: isDark,
                      gradientColors: [
                        (isDark ? Colors.black : Colors.white).withValues(
                          alpha: 0.8,
                        ),
                        (isDark ? Colors.black : Colors.white).withValues(
                          alpha: 0.8,
                        ),
                      ],
                      padding: const EdgeInsets.all(24),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Order Summary Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  'K ${_total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Total Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'K ${_total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    (_items.isEmpty ||
                                        _paymentScreenshot == null)
                                    ? null
                                    : _placeOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: isDark
                                      ? Colors.black
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: accentColor
                                      .withValues(alpha: 0.3),
                                ),
                                child: Text(
                                  _paymentScreenshot == null
                                      ? 'Upload Payment to Order'
                                      : 'Place Order',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'kpay':
      case 'wavepay':
      case 'ayapay':
      case 'cbpay':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Widget _buildCartItem(
    CartItem item,
    int index,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 16,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.imageUrl != null
                        ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                        : Icon(
                            Icons.restaurant,
                            color: textColor.withValues(alpha: 0.3),
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'K ${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _updateQuantity(index, -1),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      InkWell(
                        onTap: () => _updateQuantity(index, 1),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.add, size: 16, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
