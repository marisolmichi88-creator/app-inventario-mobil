import { View, Text, StyleSheet, TextInput, TouchableOpacity, Alert, ScrollView, Modal, FlatList } from "react-native";
import { useState, useEffect } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";
import { Ionicons } from "@expo/vector-icons";

import { colors } from "@/theme/colors";
import { Product } from "@/types/inventory";

export default function MovementFormScreen() {
  const router = useRouter();
  const db = useSQLiteContext();
  const { barcode } = useLocalSearchParams<{ barcode?: string }>();

  const [type, setType] = useState<"entrada" | "salida">("salida");
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [projectSearch, setProjectSearch] = useState("");
  const [selectedProject, setSelectedProject] = useState<{id: string, name: string} | null>(null);
  const [projectModalVisible, setProjectModalVisible] = useState(false);
  const [projectsList, setProjectsList] = useState<{id: string, name: string}[]>([]);

  // Pre-cargar producto si viene del escáner
  useEffect(() => {
    if (barcode) {
      db.getFirstAsync<Product>("SELECT id, name, stock, unit FROM products WHERE barcode = ?", [barcode])
        .then(prod => {
          if (prod) setSelectedProduct(prod);
        })
        .catch(e => console.error(e));
    }
  }, [barcode, db]);

  useEffect(() => {
    if (modalVisible && products.length === 0) {
      db.getAllAsync<Product>("SELECT id, name, stock, unit FROM products ORDER BY name ASC")
        .then(setProducts)
        .catch(e => console.error(e));
    }
  }, [modalVisible, db]);

  useEffect(() => {
    if (projectModalVisible && projectsList.length === 0) {
      db.getAllAsync<{id: string, name: string}>("SELECT id, name FROM projects ORDER BY name ASC")
        .then(setProjectsList)
        .catch(e => console.error(e));
    }
  }, [projectModalVisible, db]);

  const filteredProducts = products.filter(p => 
    p.name.toLowerCase().includes(search.toLowerCase())
  );

  const filteredProjects = projectsList.filter(p => 
    p.name.toLowerCase().includes(projectSearch.toLowerCase())
  );

  const handleSave = async () => {
    if (!selectedProduct) {
      Alert.alert("Error", "Debes seleccionar un producto.");
      return;
    }
    const qty = parseFloat(quantity);
    if (isNaN(qty) || qty <= 0) {
      Alert.alert("Error", "Ingresa una cantidad válida mayor a 0.");
      return;
    }
    if (type === "salida" && !selectedProject) {
      Alert.alert("Error", "Debes seleccionar un proyecto o destino para la salida.");
      return;
    }

    if (type === "salida" && qty > selectedProduct.stock) {
      Alert.alert("Error", `No hay suficiente stock. Tienes ${selectedProduct.stock} disponible.`);
      return;
    }

    const executeSave = async () => {
      setLoading(true);
      try {
        await db.withTransactionAsync(async () => {
          // 1. Registrar movimiento
          const newId = `mov-${Date.now()}`;
          const projId = selectedProject ? selectedProject.id : 'general';
          await db.runAsync(
            `INSERT INTO movements (id, type, product_id, quantity, project_id, date, sync_status) 
             VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
            [newId, type, selectedProduct.id, qty, projId, new Date().toISOString()]
          );
  
          // 2. Actualizar stock
          const stockChange = type === "entrada" ? qty : -qty;
          await db.runAsync(
            `UPDATE products SET stock = stock + ?, sync_status = 'pending' WHERE id = ?`,
            [stockChange, selectedProduct.id]
          );
        });
        router.back();
      } catch (e: any) {
        console.error("Error saving movement", e);
        Alert.alert("Error", "No se pudo registrar el movimiento.");
      } finally {
        setLoading(false);
      }
    };

    if (type === "salida" && (selectedProduct.stock - qty) < selectedProduct.minStock) {
      Alert.alert(
        "Advertencia de Stock Mínimo",
        `Esta salida dejará el producto por debajo de su stock mínimo (${selectedProduct.minStock} ${selectedProduct.unit}). ¿Deseas continuar de todos modos?`,
        [
          { text: "Cancelar", style: "cancel" },
          { text: "Sí, Registrar", style: "destructive", onPress: executeSave }
        ]
      );
    } else {
      executeSave();
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.scrollContent}>
      
      <View style={styles.typeSelector}>
        <TouchableOpacity 
          style={[styles.typeBtn, type === "salida" && styles.typeBtnActiveSalida]}
          onPress={() => setType("salida")}
        >
          <Ionicons name="arrow-up" size={20} color={type === "salida" ? "white" : colors.danger} />
          <Text style={[styles.typeBtnText, type === "salida" && styles.typeBtnTextActive]}>Salida</Text>
        </TouchableOpacity>
        <TouchableOpacity 
          style={[styles.typeBtn, type === "entrada" && styles.typeBtnActiveEntrada]}
          onPress={() => setType("entrada")}
        >
          <Ionicons name="arrow-down" size={20} color={type === "entrada" ? "white" : colors.success} />
          <Text style={[styles.typeBtnText, type === "entrada" && styles.typeBtnTextActive]}>Entrada</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formGroup}>
        <Text style={styles.label}>Producto *</Text>
        <TouchableOpacity style={styles.productSelector} onPress={() => setModalVisible(true)}>
          <Text style={selectedProduct ? styles.productSelectedText : styles.placeholder}>
            {selectedProduct ? selectedProduct.name : "Seleccionar un producto..."}
          </Text>
          <Ionicons name="chevron-down" size={20} color={colors.muted} />
        </TouchableOpacity>
      </View>

      {selectedProduct && (
        <View style={styles.stockInfo}>
          <Text style={styles.stockText}>Stock disponible: {selectedProduct.stock} {selectedProduct.unit}</Text>
        </View>
      )}

      <View style={styles.formGroup}>
        <Text style={styles.label}>Cantidad *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. 10"
          value={quantity}
          onChangeText={setQuantity}
          keyboardType="numeric"
        />
      </View>

      {type === "salida" && (
        <View style={styles.formGroup}>
          <Text style={styles.label}>Proyecto / Destino *</Text>
          <TouchableOpacity style={styles.productSelector} onPress={() => setProjectModalVisible(true)}>
            <Text style={selectedProject ? styles.productSelectedText : styles.placeholder}>
              {selectedProject ? selectedProject.name : "Seleccionar un proyecto..."}
            </Text>
            <Ionicons name="chevron-down" size={20} color={colors.muted} />
          </TouchableOpacity>
        </View>
      )}

      <TouchableOpacity 
        style={[styles.saveBtn, loading && styles.saveBtnDisabled]}
        onPress={handleSave}
        disabled={loading}
      >
        <Text style={styles.saveBtnText}>{loading ? "Registrando..." : "Registrar Movimiento"}</Text>
      </TouchableOpacity>
      

      {/* Selector Modal */}
      <Modal visible={modalVisible} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setModalVisible(false)}>
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Seleccionar Producto</Text>
            <TouchableOpacity onPress={() => setModalVisible(false)}>
              <Ionicons name="close" size={28} color={colors.text} />
            </TouchableOpacity>
          </View>
          <View style={styles.modalSearchBox}>
            <Ionicons name="search" size={20} color={colors.muted} style={{marginRight: 8}} />
            <TextInput 
              style={styles.modalSearchInput}
              placeholder="Buscar producto..."
              value={search}
              onChangeText={setSearch}
              autoFocus
            />
          </View>
          <FlatList 
            data={filteredProducts}
            keyExtractor={item => item.id}
            renderItem={({item}) => (
              <TouchableOpacity 
                style={styles.modalItem}
                onPress={() => {
                  setSelectedProduct(item);
                  setModalVisible(false);
                }}
              >
                <Text style={styles.modalItemName}>{item.name}</Text>
                <Text style={styles.modalItemStock}>{item.stock} {item.unit}</Text>
              </TouchableOpacity>
            )}
            ItemSeparatorComponent={() => <View style={styles.modalDivider} />}
          />
        </View>
      </Modal>

      {/* Selector de Proyectos Modal */}
      <Modal visible={projectModalVisible} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setProjectModalVisible(false)}>
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Seleccionar Proyecto</Text>
            <TouchableOpacity onPress={() => setProjectModalVisible(false)}>
              <Ionicons name="close" size={28} color={colors.text} />
            </TouchableOpacity>
          </View>
          <View style={styles.modalSearchBox}>
            <Ionicons name="search" size={20} color={colors.muted} style={{marginRight: 8}} />
            <TextInput 
              style={styles.modalSearchInput}
              placeholder="Buscar proyecto..."
              value={projectSearch}
              onChangeText={setProjectSearch}
            />
          </View>
          <FlatList 
            data={filteredProjects}
            keyExtractor={item => item.id}
            renderItem={({item}) => (
              <TouchableOpacity 
                style={styles.modalItem}
                onPress={() => {
                  setSelectedProject(item);
                  setProjectModalVisible(false);
                }}
              >
                <Text style={styles.modalItemName}>{item.name}</Text>
              </TouchableOpacity>
            )}
            ItemSeparatorComponent={() => <View style={styles.modalDivider} />}
            ListEmptyComponent={<Text style={{padding:20,textAlign:'center',color:colors.muted}}>No se encontraron proyectos. Crea uno en el módulo administrativo.</Text>}
          />
        </View>
      </Modal>

    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  scrollContent: { padding: 20, gap: 20, paddingBottom: 40 },
  typeSelector: { flexDirection: "row", gap: 10 },
  typeBtn: {
    flex: 1, flexDirection: "row", alignItems: "center", justifyContent: "center",
    padding: 14, borderRadius: 8, borderWidth: 1, borderColor: colors.border, gap: 8
  },
  typeBtnActiveSalida: { backgroundColor: colors.danger, borderColor: colors.danger },
  typeBtnActiveEntrada: { backgroundColor: colors.success, borderColor: colors.success },
  typeBtnText: { fontSize: 16, fontWeight: "600", color: colors.text },
  typeBtnTextActive: { color: "white" },
  formGroup: { gap: 8 },
  label: { fontSize: 14, fontWeight: "600", color: colors.text },
  input: {
    backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border,
    borderRadius: 8, padding: 14, fontSize: 15, color: colors.text
  },
  productSelector: {
    backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border,
    borderRadius: 8, padding: 14, flexDirection: "row", justifyContent: "space-between", alignItems: "center"
  },
  placeholder: { color: colors.muted, fontSize: 15 },
  productSelectedText: { color: colors.text, fontSize: 15, fontWeight: "600", flex: 1 },
  stockInfo: { backgroundColor: colors.surface, padding: 10, borderRadius: 8, borderWidth: 1, borderColor: colors.primary, marginTop: -10 },
  stockText: { color: colors.primary, fontWeight: "600", textAlign: "center" },
  saveBtn: { backgroundColor: colors.primary, padding: 16, borderRadius: 8, alignItems: "center", marginTop: 10 },
  saveBtnDisabled: { opacity: 0.7 },
  saveBtnText: { color: "white", fontSize: 16, fontWeight: "bold" },
  
  modalContainer: { flex: 1, backgroundColor: colors.background },
  modalHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", padding: 20, borderBottomWidth: 1, borderBottomColor: colors.border },
  modalTitle: { fontSize: 18, fontWeight: "bold", color: colors.text },
  modalSearchBox: { flexDirection: "row", alignItems: "center", margin: 16, paddingHorizontal: 12, backgroundColor: colors.surface, borderRadius: 8, borderWidth: 1, borderColor: colors.border },
  modalSearchInput: { flex: 1, paddingVertical: 12, fontSize: 16, color: colors.text },
  modalItem: { padding: 16, flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  modalItemName: { fontSize: 15, color: colors.text, flex: 1, paddingRight: 10 },
  modalItemStock: { fontSize: 14, fontWeight: "bold", color: colors.success },
  modalDivider: { height: 1, backgroundColor: colors.border, marginLeft: 16 }
});
