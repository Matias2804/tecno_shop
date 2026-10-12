const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

initializeApp({ projectId: "tecnoshop-9c08d" });

const db = getFirestore();

async function main() {
  await db.collection("productos").doc("producto_prueba").set({
    nombre: "Producto de prueba",
    precio: 1000,
    stock: 5,
    activo: true,
    categoria: "Prueba",
    descripcion: "Producto para probar la compra",
    imagenUrl: ""
  });

  console.log("Producto creado correctamente en Firestore local.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
