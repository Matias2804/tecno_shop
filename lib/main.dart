
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/producto_service.dart';
import 'models/producto.dart';
import 'screens/detalle_producto_screen.dart';
import 'services/carrito_service.dart';
import 'screens/carrito_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const usarEmuladores = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  if (usarEmuladores) {
    // Solo se conectan los servicios locales cuando se solicita
    // explícitamente el modo emulador.
    FirebaseFirestore.instance.useFirestoreEmulator(
      '127.0.0.1',
      8080,
    );

    FirebaseAuth.instance.useAuthEmulator(
      '127.0.0.1',
      9099,
    );

    FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).useFunctionsEmulator(
      '127.0.0.1',
      5001,
    );

    debugPrint('TecnoShop: conectado a los emuladores locales.');
  } else {
    debugPrint('TecnoShop: modo Firebase de producción.');
  }

  runApp(const TecnoShopApp());
}


class TecnoShopApp extends StatelessWidget {
  const TecnoShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TecnoShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A00),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8FA),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFFF7A00),
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().cambiosUsuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const CatalogoTemporalScreen();
        }

        return const LoginScreen();
      },
    );
  }
}


class CatalogoTemporalScreen extends StatefulWidget {
  const CatalogoTemporalScreen({super.key});

  @override
  State<CatalogoTemporalScreen> createState() =>
      _CatalogoTemporalScreenState();
}

class _CatalogoTemporalScreenState
    extends State<CatalogoTemporalScreen> {
  final TextEditingController _busquedaController =
      TextEditingController();
  final CarritoService _carrito = CarritoService();

  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TecnoShop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
  tooltip: 'Mi carrito',
  icon: ListenableBuilder(
    listenable: _carrito,
    builder: (context, child) {
      return Badge(
        label: Text('${_carrito.cantidadTotal}'),
        isLabelVisible: _carrito.cantidadTotal > 0,
        child: const Icon(Icons.shopping_cart_outlined),
      );
    },
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarritoScreen(carrito: _carrito),
      ),
    );
  },
),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService().cerrarSesion();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<Producto>>(
        stream: ProductoService().obtenerProductos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los productos.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final productos = (snapshot.data ?? [])
              .where((producto) => producto.activo)
              .toList();

          final categorias = productos
              .map((producto) => producto.categoria)
              .toSet()
              .toList()
            ..sort();

          final opcionesCategorias = ['Todas', ...categorias];

          final categoriaActual =
              opcionesCategorias.contains(_categoriaSeleccionada)
                  ? _categoriaSeleccionada
                  : 'Todas';

          final productosFiltrados = productos.where((producto) {
            final coincideBusqueda = producto.nombre
                .toLowerCase()
                .contains(_busqueda.trim().toLowerCase());

            final coincideCategoria =
                categoriaActual == 'Todas' ||
                producto.categoria == categoriaActual;

            return coincideBusqueda && coincideCategoria;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido a TecnoShop!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(usuario?.email ?? ''),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _busquedaController,
                      decoration: InputDecoration(
                        labelText: 'Buscar productos',
                        hintText: 'Ej. Audífonos Bluetooth',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpiar búsqueda',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _busquedaController.clear();
                                  setState(() => _busqueda = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (valor) {
                        setState(() => _busqueda = valor);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoriaActual,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por categoría',
                        prefixIcon: const Icon(Icons.filter_list),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: opcionesCategorias.map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() {
                            _categoriaSeleccionada = valor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${productosFiltrados.length} productos encontrados',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: productosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron productos.\n'
                          'Prueba otra búsqueda o categoría.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 285,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = productosFiltrados[index];

                          
return Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleProductoScreen(
            producto: producto,
            onAgregarAlCarrito: () {
  final agregado = _carrito.agregarProducto(producto);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        agregado
            ? '${producto.nombre} agregado al carrito'
            : 'No hay stock suficiente para agregar este producto',
      ),
    ),
  );

  if (agregado) {
    Navigator.pop(context);
  }
},
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: producto.imagenUrl.isEmpty
                  ? const Icon(Icons.devices, size: 64)
                  : Image.network(
                      producto.imagenUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.devices, size: 64);
                      },
                    ),
            ),
          ),
          Text(
            producto.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(producto.categoria),
          Text(
            '\$${producto.precio}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          Text('Stock disponible: ${producto.stock}'),
          const SizedBox(height: 4),
          const Text(
            'Ver detalle →',
            style: TextStyle(color: Colors.deepOrange),
          ),
        ],
      ),
    ),
  ),
);

                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}


