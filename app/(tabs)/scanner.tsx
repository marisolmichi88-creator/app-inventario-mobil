import { Ionicons } from "@expo/vector-icons";
import { StyleSheet, Text, View, TouchableOpacity, Alert, Button } from "react-native";
import { useState } from "react";
import { CameraView, useCameraPermissions } from "expo-camera";
import { useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

export default function ScannerScreen() {
  const router = useRouter();
  const db = useSQLiteContext();
  const [permission, requestPermission] = useCameraPermissions();
  const [scanned, setScanned] = useState(false);

  if (!permission) {
    return <View />;
  }

  if (!permission.granted) {
    return (
      <View style={styles.screen}>
        <Text style={styles.title}>Permiso requerido</Text>
        <Text style={styles.body}>Necesitamos tu permiso para usar la cámara y escanear códigos de barras.</Text>
        <TouchableOpacity style={styles.button} onPress={requestPermission}>
          <Text style={styles.buttonText}>Otorgar Permiso</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleBarcodeScanned = async ({ type, data }: { type: string; data: string }) => {
    setScanned(true);
    
    try {
      const prod = await db.getFirstAsync("SELECT id FROM products WHERE barcode = ?", [data]);
      if (prod) {
        // Encontrado: abrir formulario de movimiento
        router.push({ pathname: "/admin/movement-form", params: { barcode: data } });
      } else {
        // No encontrado
        Alert.alert(
          "Producto no encontrado",
          `El código ${data} no está registrado. ¿Deseas agregarlo al sistema?`,
          [
            { text: "Cancelar", style: "cancel", onPress: () => setScanned(false) },
            { 
              text: "Crear Producto", 
              onPress: () => {
                // Ir a crear producto y (futuro) pasarle el barcode
                setScanned(false);
                router.push("/admin/product-form");
              }
            }
          ]
        );
      }
    } catch (e) {
      console.error(e);
      Alert.alert("Error", "Ocurrió un error al buscar el producto.");
      setScanned(false);
    }
  };

  return (
    <View style={styles.container}>
      <CameraView
        style={StyleSheet.absoluteFillObject}
        facing="back"
        barcodeScannerSettings={{
          barcodeTypes: ["qr", "ean13", "ean8", "upc_a", "upc_e", "code39", "code128"],
        }}
        onBarcodeScanned={scanned ? undefined : handleBarcodeScanned}
      >
        <View style={styles.overlay}>
          <View style={styles.scanBox} />
          <Text style={styles.scanText}>Apunta al código de barras o QR</Text>
          {scanned && (
            <TouchableOpacity style={styles.scanBtn} onPress={() => setScanned(false)}>
              <Text style={styles.scanBtnText}>Escanear de nuevo</Text>
            </TouchableOpacity>
          )}
        </View>
      </CameraView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black'
  },
  screen: {
    alignItems: "center",
    backgroundColor: colors.background,
    flex: 1,
    justifyContent: "center",
    padding: 20,
    gap: 15
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  scanBox: {
    width: 250,
    height: 250,
    borderWidth: 2,
    borderColor: colors.primary,
    backgroundColor: 'transparent',
    borderRadius: 10,
    marginBottom: 20
  },
  scanText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
    backgroundColor: 'rgba(0,0,0,0.7)',
    padding: 10,
    borderRadius: 8
  },
  scanBtn: {
    marginTop: 20,
    backgroundColor: colors.primary,
    padding: 15,
    borderRadius: 8
  },
  scanBtnText: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16
  },
  title: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "bold",
    textAlign: "center"
  },
  body: {
    color: colors.muted,
    fontSize: 15,
    textAlign: "center"
  },
  button: {
    backgroundColor: colors.primary,
    padding: 15,
    borderRadius: 8
  },
  buttonText: {
    color: "white",
    fontWeight: "bold"
  }
});
