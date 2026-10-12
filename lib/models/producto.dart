
class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int precio;
  final int stock;
  final String imagenUrl;
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.imagenUrl,
    this.activo = true,
  });

  factory Producto.fromMap(
    String id,
    Map<String, dynamic> datos,
  ) {
    return Producto(
      id: id,
      nombre: datos['nombre']?.toString() ?? 'Producto sin nombre',
      descripcion: datos['descripcion']?.toString() ?? '',
      categoria: datos['categoria']?.toString() ?? 'Sin categoría',
      precio: (datos['precio'] as num?)?.toInt() ?? 0,
      stock: (datos['stock'] as num?)?.toInt() ?? 0,
      imagenUrl: datos['imagenUrl']?.toString() ?? '',
      activo: datos['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
      'imagenUrl': imagenUrl,
      'activo': activo,
    };
  }
}
