
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item_carrito.dart';

class CompraService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<String> realizarCompra(List<ItemCarrito> items) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para comprar.');
    }

    if (items.isEmpty) {
      throw Exception('El carrito está vacío.');
    }

    final productosCompra = items.map((item) {
      return {
        'productoId': item.producto.id,
        'cantidad': item.cantidad,
      };
    }).toList();

    try {
      final callable = _functions.httpsCallable('realizarCompra');

      final resultado = await callable.call({
        'items': productosCompra,
      });

      final datos = Map<String, dynamic>.from(resultado.data as Map);
      final compraId = datos['compraId'] as String?;

      if (compraId == null || compraId.isEmpty) {
        throw Exception('No se recibió el identificador de la compra.');
      }

      return compraId;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'No se pudo completar la compra.');
    }
  }
}
