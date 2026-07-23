import 'package:flutter/material.dart';
import 'package:get/utils.dart';
import 'package:tanzan/edit_rent_request.dart';
import 'package:tanzan/rent_request_screen.dart';
import 'package:tanzan/show_my_apartments.dart';

class MyApartmentScreen extends StatelessWidget {
  const MyApartmentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Apartments'.tr,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => ShowMyApartmentScreen()),
                );
              },
              child: Card(
                color: const Color(0xFF3B5998),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show my apartments'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge!.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => RentRequestScreen()),
                );
              },
              child: Card(
                color: const Color(0xFF3B5998),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent requests'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge!.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => EditRentRequestScreen()),
                );
              },
              child: Card(
                color: const Color(0xFF3B5998),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editing rent requests'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge!.copyWith(fontSize: 16),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
