import { FlatList, StyleSheet, Text, View, TouchableOpacity, Alert } from "react-native";
import { useState, useCallback } from "react";
import { useSQLiteContext } from "expo-sqlite";
import { useRouter, useFocusEffect } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';

import { colors } from "@/theme/colors";

type MovementRow = {
  id: string;
  type: string;
  productName: string;
  quantity: number;
  project: string;
  date: string;
};

export default function MovementsScreen() {
  const db = useSQLiteContext();
  const router = useRouter();
  const [movements, setMovements] = useState<MovementRow[]>([]);

  useFocusEffect(
    useCallback(() => {
      let isActive = true;
      async function fetchMovements() {
        try {
          const result = await db.getAllAsync<MovementRow>(
            `SELECT m.id, m.type, m.quantity, m.date, 
                    p.name as productName, 
                    pr.name as project
             FROM movements m
             LEFT JOIN products p ON m.product_id = p.id
             LEFT JOIN projects pr ON m.project_id = pr.id
             ORDER BY m.date DESC`
          );
          if (isActive) setMovements(result);
        } catch (error) {
          console.error("Error fetching movements:", error);
        }
      }
      fetchMovements();
      return () => { isActive = false; };
    }, [db])
  );

  const exportToCSV = async () => {
    if (movements.length === 0) {
      Alert.alert("Sin datos", "No hay movimientos para exportar.");
      return;
    }
    
    let csvString = "ID,Tipo,Producto,Cantidad,Proyecto,Fecha\n";
    movements.forEach(m => {
      const dateStr = new Date(m.date).toLocaleString().replace(/,/g, "");
      const prodName = (m.productName || 'Producto Eliminado').replace(/"/g, '""');
      const projName = (m.project || 'General').replace(/"/g, '""');
      csvString += `"${m.id}","${m.type}","${prodName}",${m.quantity},"${projName}","${dateStr}"\n`;
    });

    try {
      const fileUri = FileSystem.documentDirectory + "reporte_movimientos.csv";
      await FileSystem.writeAsStringAsync(fileUri, csvString, { encoding: FileSystem.EncodingType.UTF8 });
      
      const isSharingAvailable = await Sharing.isAvailableAsync();
      if (isSharingAvailable) {
        await Sharing.shareAsync(fileUri, {
          mimeType: 'text/csv',
          dialogTitle: 'Exportar Reporte de Movimientos'
        });
      } else {
        Alert.alert("Aviso", "La función de compartir no está disponible en este dispositivo.");
      }
    } catch (e) {
      console.error(e);
      Alert.alert("Error", "Ocurrió un error al exportar el archivo.");
    }
  };

  return (
    <View style={styles.screen}>
      <View style={styles.actionsBar}>
        <Text style={styles.title}>Historial</Text>
        <TouchableOpacity style={styles.exportBtn} onPress={exportToCSV}>
          <Ionicons name="download-outline" size={20} color="white" />
          <Text style={styles.exportText}>Exportar CSV</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        contentContainerStyle={styles.list}
        data={movements}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={styles.header}>
              <Text style={styles.product}>{item.productName || 'Producto Eliminado'}</Text>
              <Text style={item.type === "entrada" ? styles.in : styles.out}>
                {item.type === "entrada" ? "Entrada" : "Salida"}
              </Text>
            </View>
            <Text style={styles.meta}>Cantidad: {item.quantity}</Text>
            <Text style={styles.meta}>Proyecto: {item.project || 'N/A'}</Text>
            <Text style={styles.date}>{new Date(item.date).toLocaleString()}</Text>
          </View>
        )}
        ListEmptyComponent={<Text style={styles.meta}>No hay movimientos registrados.</Text>}
      />

      <TouchableOpacity 
        style={styles.fab}
        onPress={() => router.push("/admin/movement-form")}
      >
        <Ionicons name="add" size={30} color="white" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background
  },
  actionsBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 8
  },
  title: {
    fontSize: 20,
    fontWeight: "bold",
    color: colors.text
  },
  exportBtn: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.success,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    gap: 6
  },
  exportText: {
    color: "white",
    fontWeight: "bold"
  },
  list: {
    gap: 10,
    padding: 16
  },
  card: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: 8,
    borderWidth: 1,
    gap: 5,
    padding: 14
  },
  header: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 10,
    justifyContent: "space-between"
  },
  product: {
    color: colors.text,
    flex: 1,
    fontSize: 15,
    fontWeight: "800"
  },
  meta: {
    color: colors.muted,
    fontSize: 13
  },
  date: {
    color: colors.text,
    fontSize: 12,
    fontWeight: "700",
    marginTop: 4
  },
  in: {
    color: colors.success,
    fontSize: 13,
    fontWeight: "800"
  },
  out: {
    color: colors.danger,
    fontSize: 13,
    fontWeight: "800"
  },
  fab: {
    position: "absolute",
    bottom: 24,
    right: 24,
    backgroundColor: colors.primary,
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5
  }
});
