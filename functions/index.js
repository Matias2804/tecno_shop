
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

initializeApp();

setGlobalOptions({
  region: "us-central1",
});

const db = getFirestore();

exports.realizarCompra = onCall(async (request) => {
  // 1. Verificar que el usuario haya iniciado sesión.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Debes iniciar sesión para comprar."
    );
  }

  const items = request.data?.items;

  if (!Array.isArray(items) || items.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "El carrito está vacío."
    );
  }

  // 2. Validar y agrupar cantidades por producto.
  const cantidades = new Map();

  for (const item of items) {
    const id = item?.productoId;
    const cantidad = item?.cantidad;

    if (
      typeof id !== "string" ||
      id.trim() === "" ||
      !Number.isSafeInteger(cantidad) ||
      cantidad <= 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Los datos del carrito no son válidos."
      );
    }

    const nuevaCantidad = (cantidades.get(id) || 0) + cantidad;

    if (!Number.isSafeInteger(nuevaCantidad)) {
      throw new HttpsError(
        "invalid-argument",
        "La cantidad solicitada no es válida."
      );
    }

    cantidades.set(id, nuevaCantidad);
  }

  if (cantidades.size > 100) {
    throw new HttpsError(
      "invalid-argument",
      "Hay demasiados productos en el pedido."
    );
  }

  const referencias = Array.from(cantidades.keys()).map(
    (id) => db.collection("productos").doc(id)
  );

  const referenciaCompra = db.collection("compras").doc();

  // 3. Leer y validar todo antes de realizar escrituras.
  const resultado = await db.runTransaction(async (tx) => {
    const documentos = await Promise.all(
      referencias.map((ref) => tx.get(ref))
    );

    const lineas = [];
    let total = 0;

    for (let i = 0; i < documentos.length; i++) {
      const documento = documentos[i];
      const referencia = referencias[i];
      const cantidad = cantidades.get(referencia.id);

      if (!documento.exists) {
        throw new HttpsError(
          "not-found",
          "Uno de los productos ya no existe."
        );
      }

      const producto = documento.data();
      const stock = producto.stock;
      const precio = producto.precio;

      if (producto.activo !== true) {
        throw new HttpsError(
          "failed-precondition",
          `${producto.nombre} no está disponible.`
        );
      }

      if (
        !Number.isSafeInteger(stock) ||
        !Number.isSafeInteger(precio) ||
        stock < 0 ||
        precio < 0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Los datos de stock o precio no son válidos."
        );
      }

      if (stock < cantidad) {
        throw new HttpsError(
          "failed-precondition",
          `Stock insuficiente para ${producto.nombre}.`
        );
      }

      const subtotal = precio * cantidad;
      total += subtotal;

      if (
        !Number.isSafeInteger(subtotal) ||
        !Number.isSafeInteger(total)
      ) {
        throw new HttpsError(
          "failed-precondition",
          "El total de la compra no es válido."
        );
      }

      lineas.push({
        productoId: documento.id,
        nombre: producto.nombre,
        precio,
        cantidad,
        subtotal,
      });
    }

    // 4. Descontar stock y registrar la compra.
    for (let i = 0; i < documentos.length; i++) {
      const referencia = referencias[i];
      const producto = documentos[i].data();
      const cantidad = cantidades.get(referencia.id);

      tx.update(referencia, {
        stock: producto.stock - cantidad,
      });
    }

    tx.set(referenciaCompra, {
      usuarioId: request.auth.uid,
      correo: request.auth.token.email || null,
      productos: lineas,
      total,
      estado: "confirmada",
      fecha: FieldValue.serverTimestamp(),
    });

    return { total };
  });

  return {
    compraId: referenciaCompra.id,
    total: resultado.total,
    mensaje: "Compra realizada correctamente.",
  };
});
