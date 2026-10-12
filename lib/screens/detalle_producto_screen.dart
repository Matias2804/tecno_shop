
import 'package:flutter/material.dart';
import '../models/producto.dart';

class DetalleProductoScreen extends StatelessWidget {
  final Producto producto;
  final VoidCallback onAgregarAlCarrito;

  const DetalleProductoScreen({
    super.key,
    required this.producto,
    required this.onAgregarAlCarrito,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 240,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: producto.imagenUrl.isNotEmpty
                ? Image.network(
                    producto.imagenUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.devices, size: 100);
                    },
                  )
                : const Icon(Icons.devices, size: 100),
          ),
          const SizedBox(height: 24),
          Text(
            producto.nombre,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Chip(label: Text(producto.categoria)),
          const SizedBox(height: 12),
          Text(
            '\$${producto.precio}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            producto.descripcion,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined),
              const SizedBox(width: 8),
              Text('Stock disponible: ${producto.stock}'),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: producto.stock > 0
                ? onAgregarAlCarrito
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              producto.stock > 0
                  ? 'Agregar al carrito'
                  : 'Producto sin stock',
            ),
          ),
        ],
      ),
    );
  }
}
