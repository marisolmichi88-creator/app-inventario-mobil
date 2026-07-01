import { View, Text, StyleSheet, TextInput, TouchableOpacity, Alert, ScrollView } from "react-native";
import { useState, useEffect } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";
import { Product } from "@/types/inventory";

export default function ProductFormScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const db = useSQLiteContext();

  const isEditing = !!id;

  const [name, setName] = useState("");
  const [category, setCategory] = useState("Sin Categoria");
  const [warehouse, setWarehouse] = useState("General");
  const [barcode, setBarcode] = useState("");
  const [unit, setUnit] = useState("UND");
  const [stock, setStock] = useState("0");
  const [minStock, setMinStock] = useState("0");
  const [currency, setCurrency] = useState("PEN");
  const [unitCost, setUnitCost] = useState("0");
  
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      async function loadProduct() {
        try {
          const prod = await db.getFirstAsync<any>(
            "SELECT * FROM products WHERE id = ?", [id as string]
          );
          if (prod) {
            setName(prod.name || "");
            setCategory(prod.category_id || "Sin Categoria");
            setWarehouse(prod.warehouse_id || "General");
            setBarcode(prod.barcode || "");
            setUnit(prod.unit || "UND");
            setStock((prod.stock || 0).toString());
            setMinStock((prod.min_stock || 0).toString());
            setCurrency(prod.currency || "PEN");
            setUnitCost((prod.unit_cost || 0).toString());
          }
        } catch (e) {
          console.error("Error loading product", e);
        }
      }
      loadProduct();
    }
  }, [id, db]);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert("Error", "El nombre del producto no puede estar vacío.");
      return;
    }

    setLoading(true);
    try {
      const parsedStock = parseInt(stock) || 0;
      const parsedMinStock = parseInt(minStock) || 0;
      const parsedCost = parseFloat(unitCost) || 0;

      if (isEditing) {
        await db.runAsync(
          `UPDATE products 
           SET name=?, category_id=?, warehouse_id=?, barcode=?, unit=?, stock=?, min_stock=?, currency=?, unit_cost=?, sync_status='pending' 
           WHERE id=?`,
          [name.trim(), category.trim(), warehouse.trim(), barcode.trim(), unit.trim(), parsedStock, parsedMinStock, currency.trim(), parsedCost, id as string]
        );
      } else {
        const newId = `prod-${Date.now()}`;
        await db.runAsync(
          `INSERT INTO products (id, name, category_id, warehouse_id, barcode, unit, stock, min_stock, currency, unit_cost, sync_status) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
          [newId, name.trim(), category.trim(), warehouse.trim(), barcode.trim(), unit.trim(), parsedStock, parsedMinStock, currency.trim(), parsedCost]
        );
      }
      router.back();
    } catch (e: any) {
      console.error("Error saving product", e);
      Alert.alert("Error", "No se pudo guardar el producto.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.scrollContent}>
      
      <View style={styles.formGroup}>
        <Text style={styles.label}>Nombre del Producto *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. Taladro Percutor"
          value={name}
          onChangeText={setName}
        />
      </View>

      <View style={styles.row}>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Categoría</Text>
          <TextInput 
            style={styles.input}
            value={category}
            onChangeText={setCategory}
          />
        </View>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Almacén</Text>
          <TextInput 
            style={styles.input}
            value={warehouse}
            onChangeText={setWarehouse}
          />
        </View>
      </View>

      <View style={styles.row}>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Código/SKU</Text>
          <TextInput 
            style={styles.input}
            value={barcode}
            onChangeText={setBarcode}
          />
        </View>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Unidad (UND, KG)</Text>
          <TextInput 
            style={styles.input}
            value={unit}
            onChangeText={setUnit}
            autoCapitalize="characters"
          />
        </View>
      </View>

      <View style={styles.row}>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Stock Actual</Text>
          <TextInput 
            style={styles.input}
            value={stock}
            onChangeText={setStock}
            keyboardType="numeric"
          />
        </View>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Stock Mínimo</Text>
          <TextInput 
            style={styles.input}
            value={minStock}
            onChangeText={setMinStock}
            keyboardType="numeric"
          />
        </View>
      </View>

      <View style={styles.row}>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Moneda</Text>
          <TextInput 
            style={styles.input}
            value={currency}
            onChangeText={setCurrency}
            autoCapitalize="characters"
          />
        </View>
        <View style={[styles.formGroup, {flex: 1}]}>
          <Text style={styles.label}>Costo Unitario</Text>
          <TextInput 
            style={styles.input}
            value={unitCost}
            onChangeText={setUnitCost}
            keyboardType="decimal-pad"
          />
        </View>
      </View>

      <TouchableOpacity 
        style={[styles.saveBtn, loading && styles.saveBtnDisabled]}
        onPress={handleSave}
        disabled={loading}
      >
        <Text style={styles.saveBtnText}>{loading ? "Guardando..." : "Guardar Producto"}</Text>
      </TouchableOpacity>
      
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContent: {
    padding: 20,
    gap: 16,
    paddingBottom: 40
  },
  row: {
    flexDirection: "row",
    gap: 16
  },
  formGroup: {
    gap: 8
  },
  label: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.text
  },
  input: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: 14,
    fontSize: 15,
    color: colors.text
  },
  saveBtn: {
    backgroundColor: colors.primary,
    padding: 16,
    borderRadius: 8,
    alignItems: "center",
    marginTop: 20
  },
  saveBtnDisabled: {
    opacity: 0.7
  },
  saveBtnText: {
    color: "white",
    fontSize: 16,
    fontWeight: "bold"
  }
});
