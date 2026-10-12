
import 'package:flutter/material.dart';

import '../services/carrito_service.dart';
import '../models/item_carrito.dart';
import '../services/compra_service.dart';

class CarritoScreen extends StatelessWidget {
  final CarritoService carrito;
  final CompraService _compraService = CompraService();

 CarritoScreen({
  super.key,
  required this.carrito,
});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: carrito,
      builder: (context, child) {
        final items = carrito.items;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi carrito'),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: 'Vaciar carrito',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: carrito.vaciar,
                ),
            ],
          ),
          body: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 72),
                      SizedBox(height: 12),
                      Text('Tu carrito está vacío'),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final ItemCarrito item = items[index];
                    final producto = item.producto;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: producto.imagenUrl.isEmpty
                            ? const Icon(Icons.devices)
                            : ClipOval(
                                child: Image.network(
                                  producto.imagenUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.devices),
                                ),
                              ),
                      ),
                      title: Text(producto.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Precio unitario: \$${producto.precio}'),
                          Text('Subtotal: \$${item.subtotal}'),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Disminuir cantidad',
                                onPressed: () {
                                  carrito.cambiarCantidad(
                                    producto.id,
                                    item.cantidad - 1,
                                  );
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                              ),
                              Text('${item.cantidad}'),
                              IconButton(
                                tooltip: 'Aumentar cantidad',
                                onPressed: item.cantidad < producto.stock
                                    ? () {
                                        carrito.cambiarCantidad(
                                          producto.id,
                                          item.cantidad + 1,
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Quitar producto',
                                onPressed: () {
                                  carrito.quitarProducto(producto.id);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${carrito.total}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
FilledButton.icon(
  onPressed: () async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          '¿Deseas comprar ${carrito.cantidadTotal} unidades '
          'por \$${carrito.total}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    // Evita cambios en el carrito mientras se procesa el pedido.
    final itemsCompra = List<ItemCarrito>.from(carrito.items);

    try {
      final compraId =
          await _compraService.realizarCompra(itemsCompra);

      if (!context.mounted) return;

      carrito.vaciar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Compra realizada! Pedido: $compraId',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  },
  icon: const Icon(Icons.shopping_bag_outlined),
  label: const Text('Confirmar compra'),
),

                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
