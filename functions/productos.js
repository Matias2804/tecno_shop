
const { onRequest } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();
const productos = db.collection("productos");

// Protección temporal para pruebas locales.
// Todas las solicitudes administrativas deben incluir este encabezado.
const CLAVE_ADMIN = process.env.CLAVE_ADMIN;

function verificarAdmin(req, res) {
  if (!CLAVE_ADMIN) {
    res.status(503).json({
      error: "La administración no está configurada.",
    });
    return false;
  }

  if (req.get("x-admin-key") !== CLAVE_ADMIN) {
    res.status(401).json({
      error: "No autorizado.",
    });
    return false;
  }

  return true;
}

function validarProducto(datos, parcial = false) {
  const permitidos = [
    "nombre",
    "descripcion",
    "categoria",
    "imagenUrl",
    "precio",
    "stock",
    "activo",
  ];

  if (!datos || typeof datos !== "object" || Array.isArray(datos)) {
    return "Debes enviar un objeto de producto válido.";
  }

  const claves = Object.keys(datos);

  if (claves.some((clave) => !permitidos.includes(clave))) {
    return "El producto contiene campos no permitidos.";
  }

  if (!parcial) {
    const obligatorios = [
      "nombre",
      "descripcion",
      "categoria",
      "imagenUrl",
      "precio",
      "stock",
      "activo",
    ];

    if (obligatorios.some((campo) => !(campo in datos))) {
      return "Faltan campos obligatorios del producto.";
    }
  }

  if ("nombre" in datos &&
      (typeof datos.nombre !== "string" || !datos.nombre.trim())) {
    return "El nombre es obligatorio.";
  }

  for (const campo of ["descripcion", "categoria", "imagenUrl"]) {
    if (campo in datos && typeof datos[campo] !== "string") {
      return `El campo ${campo} debe ser texto.`;
    }
  }

  for (const campo of ["precio", "stock"]) {
    if (campo in datos &&
        (!Number.isSafeInteger(datos[campo]) || datos[campo] < 0)) {
      return `${campo} debe ser un entero no negativo.`;
    }
  }

  if ("activo" in datos && typeof datos.activo !== "boolean") {
    return "El campo activo debe ser verdadero o falso.";
  }

  return null;
}

exports.administrarProductos = onRequest(async (req, res) => {
  res.set("Cache-Control", "no-store");

  if (!verificarAdmin(req, res)) return;

  try {
    if (req.method === "GET") {
      const snapshot = await productos.get();

      return res.status(200).json({
        productos: snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
      });
    }

    if (req.method === "POST") {
      const error = validarProducto(req.body);

      if (error) {
        return res.status(400).json({ error });
      }

      const referencia = await productos.add(req.body);

      return res.status(201).json({
        mensaje: "Producto creado correctamente.",
        id: referencia.id,
      });
    }

    if (req.method === "PUT") {
      const id = req.path.split("/").filter(Boolean).pop();

      if (!id || id === "productos") {
        return res.status(400).json({
          error: "Debes indicar el ID del producto.",
        });
      }

      const error = validarProducto(req.body, true);

      if (error) {
        return res.status(400).json({ error });
      }

      if (Object.keys(req.body).length === 0) {
        return res.status(400).json({
          error: "Debes enviar al menos un campo para actualizar.",
        });
      }

      const referencia = productos.doc(id);
      const existente = await referencia.get();

      if (!existente.exists) {
        return res.status(404).json({
          error: "El producto no existe.",
        });
      }

      await referencia.update(req.body);

      return res.status(200).json({
        mensaje: "Producto actualizado correctamente.",
        id,
      });
    }

    if (req.method === "DELETE") {
      const partesRuta = req.path.split("/").filter(Boolean);
      const id = partesRuta[partesRuta.length - 1];

      if (!id || id === "productos") {
        return res.status(400).json({
          error: "Debes indicar el ID del producto.",
        });
      }

      const referencia = productos.doc(id);
      const existente = await referencia.get();

      if (!existente.exists) {
        return res.status(404).json({
          error: "El producto no existe.",
        });
      }

      await referencia.delete();

      return res.status(200).json({
        mensaje: "Producto eliminado correctamente.",
        id,
      });
    }

    res.set("Allow", "GET, POST, PUT, DELETE");

    return res.status(405).json({
      error: "Método HTTP no permitido.",
    });
  } catch (error) {
    console.error("Error administrando productos:", error);

    return res.status(500).json({
      error: "Ocurrió un error al administrar productos.",
    });
  }
});
