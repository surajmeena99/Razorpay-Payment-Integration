import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pay/core/app_components.dart'; // Make sure this exists
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

class PurchaseView extends StatefulWidget {
  const PurchaseView({super.key});

  @override
  State<PurchaseView> createState() => _PurchaseViewState();
}

class _PurchaseViewState extends State<PurchaseView> {
  final Razorpay _razorpay = Razorpay();
  final _razorpayKeyId = "rzp_test_kyYpWmkyEILXhn"; // Add your Razorpay key
  final _razorpayKeySecret = "xGV81J8XU80cZQ94X8CL7wwd";

  final List<String> sizeList = ["S", "M", "L", "XL"];
  int qtyOfProduct = 1;
  int selectedSizePos = 0;
  int priceOfProduct = 1;
  int finalPrice = 0;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessEvent);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentFailureEvent);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleWalletResponse);
    calculateFinalPrice();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void calculateFinalPrice() {
    setState(() {
      finalPrice = priceOfProduct * qtyOfProduct;
    });
  }

  void handlePaymentSuccessEvent(PaymentSuccessResponse successResponse) {
    // Call server or verify locally
    verifyPayment(successResponse);
  }

  Future<void> verifyPayment(PaymentSuccessResponse successResponse) async {
    // You should ideally verify from your server
    debugPrint('Payment ID: ${successResponse.paymentId}');
    debugPrint('Order ID: ${successResponse.orderId}');
    debugPrint('Signature: ${successResponse.signature}');

    // Optionally: call your server API to validate payment with Payment ID and Signature
    showSnackBarView(context,
      "Payment Verified Successfully! Payment ID: ${successResponse.paymentId}",
      Colors.green,
    );

  }

  void handlePaymentFailureEvent(PaymentFailureResponse paymentFailureResponse) {
    showSnackBarView(
      context,
      "Payment Failed: ${paymentFailureResponse.message}",
      Colors.red,
    );
  }

  void handleWalletResponse(ExternalWalletResponse externalWalletResponse) {
    showSnackBarView(
      context,
      "Wallet Selected: ${externalWalletResponse.walletName}",
      Colors.blue,
    );
  }

  Future<void> createOrder() async {
    final url = Uri.parse('https://api.razorpay.com/v1/orders');
    final auth = 'Basic ' + base64Encode(utf8.encode('$_razorpayKeyId:$_razorpayKeySecret'));

    print("Token: $auth");
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': auth,
    };

    final body = jsonEncode({
      'amount': finalPrice * 100, // amount in paise
      'currency': 'INR',
      'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
      'payment_capture': 1, // auto-capture
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final orderData = jsonDecode(response.body);
      final String orderId = orderData['id'];
      print("MyOrderId: $orderId");
      openRazorPaySession(orderId);
    } else {
      debugPrint('Failed to create Razorpay order: ${response.body}');
      showSnackBarView(context, "Failed to create order", Colors.red);
    }
  }

  void openRazorPaySession(String orderId) {
    try {
      var options = {
        'key': _razorpayKeyId,
        'amount': finalPrice * 100, //in paise
        'name': 'Sun Corp',
        'description': 'Description of the purchase item shown on the Checkout form',
        'order_id': orderId,
        'timeout': 300, // in seconds
        'prefill': {
          'contact': '1234567890',
          'email': 'user@example.com',
          'name': 'User Name', // You can also prefill name
        },
        'image': 'https://rukminim2.flixcart.com/image/832/832/xif0q/jacket/m/n/4/3xl-no-tblhdfulljacket-k29-tripr-original-imaggvw7ju84qdfe.jpeg?q=70', // Add your business logo here
        'external': {
          'wallets': ['paytm']
        },
        'retry': {
          'enabled': true,
          'max_count': 2
        },
        'send_sms_hash': true,
      };
      _razorpay.open(options);
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10.0, top: 20.0),
                child: Text(
                  'CheckOut',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              productDetailsView(
                "https://rukminim2.flixcart.com/image/832/832/xif0q/jacket/m/n/4/3xl-no-tblhdfulljacket-k29-tripr-original-imaggvw7ju84qdfe.jpeg?q=70",
                "Casual Jacket",
                "Casual Jacket For Winter with 16 different colours and also available cash on delivery with selected address.",
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    createOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget productDetailsView(String imageUrl, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Image.network(
            imageUrl,
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Rs. $finalPrice",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 20.0),
          child: Text(
            "Select Size",
            style: TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(sizeList.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSizePos = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedSizePos == index ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sizeList[index],
                      style: TextStyle(
                        color: selectedSizePos == index ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 25.0),
          child: Text(
            "Quantity",
            style: TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (qtyOfProduct > 1) {
                    setState(() {
                      qtyOfProduct--;
                      calculateFinalPrice();
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.withOpacity(0.3),
                  child: const Icon(Icons.remove, color: Colors.green),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  qtyOfProduct.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    qtyOfProduct++;
                    calculateFinalPrice();
                  });
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.withOpacity(0.3),
                  child: const Icon(Icons.add, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
