
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

const nodemailer = require("nodemailer");

const smtpUser = process.env.SMTP_USER;
const smtpPassword = process.env.SMTP_APP_PASSWORD;

const transporter =
  smtpUser && smtpPassword
    ? nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: smtpUser,
          pass: smtpPassword,
        },
      })
    : null;


async function enviarCorreoCompra(correo, compraId, productos, total) {
  if (!transporter) {
    throw new Error("El servicio SMTP no está configurado.");
  }

  const formatoCLP = (valor) =>
    new Intl.NumberFormat("es-CL", {
      style: "currency",
      currency: "CLP",
      maximumFractionDigits: 0,
    }).format(valor);

  const detalle = productos
    .map(
      (producto) =>
        `- ${producto.nombre}: ${producto.cantidad} unidad(es) x ` +
        `${formatoCLP(producto.precio)} = ${formatoCLP(producto.subtotal)}`
    )
    .join("\n");

  await transporter.sendMail({
    from: `"TecnoShop" <${smtpUser}>`,
    to: correo,
    subject: `Confirmación de compra ${compraId} - TecnoShop`,
    text: [
      "¡Gracias por comprar en TecnoShop!",
      "",
      `Número de compra: ${compraId}`,
      "",
      "Detalle de tu pedido:",
      detalle,
      "",
      `Total pagado: ${formatoCLP(total)}`,
      "",
      "Tu compra ha sido registrada correctamente.",
      "Gracias por preferir TecnoShop.",
    ].join("\n"),
  });
}


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


  const correo = request.auth.token.email;

  let correoEnviado = false;

  if (correo) {
    try {
      await enviarCorreoCompra(
        correo,
        referenciaCompra.id,
        // Las líneas de detalle se guardaron en la compra.
        (await referenciaCompra.get()).data().productos,
        resultado.total
      );

      correoEnviado = true;
    } catch (error) {
      console.error("No se pudo enviar el correo de compra:", error.message);
    }
  } else {
    console.warn(
      "Compra confirmada, pero el usuario no tiene correo en su token."
    );
  }

  return {
    compraId: referenciaCompra.id,
    total: resultado.total,
    correoEnviado,
    mensaje: correoEnviado
      ? "Compra realizada correctamente. Se envió el correo de confirmación."
      : "Compra realizada correctamente, pero no se pudo enviar el correo.",
  };

});
exports.administrarProductos =
  require("./productos").administrarProductos;
