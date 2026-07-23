import 'package:get/get.dart';

class ApartmentController extends GetxController {
  var myApartments = <Map<String, dynamic>>[].obs;

  void addApartment(Map<String, dynamic> apartment) {
    myApartments.add(apartment);
  }

  void deleteApartment(int index) {
    myApartments.removeAt(index);
  }

  void updateApartment(int index, Map<String, dynamic> updatedData) {
    myApartments[index] = updatedData;
    myApartments.refresh(); // لتحديث الواجهة فوراً
  }
}