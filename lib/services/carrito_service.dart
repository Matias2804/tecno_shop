
import 'package:flutter/foundation.dart';

import '../models/item_carrito.dart';
import '../models/producto.dart';

class CarritoService extends ChangeNotifier {
  final List<ItemCarrito> _items = [];

  List<ItemCarrito> get items => List.unmodifiable(_items);

  int get cantidadTotal =>
      _items.fold(0, (total, item) => total + item.cantidad);

  int get total =>
      _items.fold(0, (suma, item) => suma + item.subtotal);

  bool agregarProducto(Producto producto, {int cantidad = 1}) {
    if (cantidad <= 0 || producto.stock < cantidad) {
      return false;
    }

    final indice = _items.indexWhere(
      (item) => item.producto.id == producto.id,
    );

    if (indice >= 0) {
      final nuevaCantidad = _items[indice].cantidad + cantidad;

      if (nuevaCantidad > producto.stock) {
        return false;
      }

      _items[indice].cantidad = nuevaCantidad;
    } else {
      _items.add(
        ItemCarrito(producto: producto, cantidad: cantidad),
      );
    }

    notifyListeners();
    return true;
  }

  void cambiarCantidad(String productoId, int cantidad) {
    final indice = _items.indexWhere(
      (item) => item.producto.id == productoId,
    );

    if (indice < 0) return;

    if (cantidad <= 0) {
      _items.removeAt(indice);
    } else if (cantidad <= _items[indice].producto.stock) {
      _items[indice].cantidad = cantidad;
    }

    notifyListeners();
  }

  void quitarProducto(String productoId) {
    _items.removeWhere(
      (item) => item.producto.id == productoId,
    );
    notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }
}
