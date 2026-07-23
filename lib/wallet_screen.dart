import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MiniWalletSheet extends StatelessWidget {
  const MiniWalletSheet({super.key, required this.walletBalance});
  final String walletBalance;
  @override
  Widget build(BuildContext context) {
    // You can adjust these colors to match your dark theme
    const Color cardColor = Color(0xFF282A3A);
    const Color blueAccent = Colors.blueAccent;

    return Container(
      // Set the height of the BottomSheet to approximately half the screen height
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Sheet Title
            Text(
              'My Wallet Balance'.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(color: Colors.white12, height: 20),

            // Wallet Balance Card
            Card(
              color: blueAccent.withOpacity(
                0.2,
              ), // Light blue background for the card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: const BorderSide(color: blueAccent, width: 2),
              ),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance'.tr,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          // Fixed value - replace with dynamic data if linked to State
                          '\$$walletBalance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Icon(
                          Icons.account_balance_wallet,
                          color: blueAccent,
                          size: 40,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (e.g., Add Funds)
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
