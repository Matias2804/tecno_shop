

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/producto.dart';

class ProductoService {
  final CollectionReference<Map<String, dynamic>> _productos =
      FirebaseFirestore.instance.collection('productos');

  Stream<List<Producto>> obtenerProductos() {
    return _productos.snapshots().map((snapshot) {
      return snapshot.docs
          .map((documento) => Producto.fromMap(
                documento.id,
                documento.data(),
              ))
          .toList();
    });
  }

  Future<Producto?> obtenerProductoPorId(String id) async {
    final documento = await _productos.doc(id).get();

    if (!documento.exists || documento.data() == null) {
      return null;
    }

    return Producto.fromMap(documento.id, documento.data()!);
  }
}

