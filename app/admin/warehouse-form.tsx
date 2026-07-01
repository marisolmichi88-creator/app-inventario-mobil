import { View, Text, StyleSheet, TextInput, TouchableOpacity, Alert } from "react-native";
import { useState, useEffect } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

export default function WarehouseFormScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const db = useSQLiteContext();

  const isEditing = !!id;

  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      async function loadWarehouse() {
        try {
          const war = await db.getFirstAsync<{name: string}>(
            "SELECT name FROM warehouses WHERE id = ?", [id as string]
          );
          if (war) {
            setName(war.name);
          }
        } catch (e) {
          console.error("Error loading warehouse", e);
        }
      }
      loadWarehouse();
    }
  }, [id, db]);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert("Error", "El nombre del almacén no puede estar vacío.");
      return;
    }

    setLoading(true);
    try {
      if (isEditing) {
        await db.runAsync(
          "UPDATE warehouses SET name = ?, sync_status = 'pending' WHERE id = ?",
          [name.trim(), id as string]
        );
      } else {
        const newId = `war-${Date.now()}`;
        await db.runAsync(
          "INSERT INTO warehouses (id, name, sync_status) VALUES (?, ?, 'pending')",
          [newId, name.trim()]
        );
      }
      router.back();
    } catch (e: any) {
      console.error("Error saving warehouse", e);
      Alert.alert("Error", "No se pudo guardar el almacén.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      
      <View style={styles.formGroup}>
        <Text style={styles.label}>Nombre del Almacén *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. Almacén Principal"
          value={name}
          onChangeText={setName}
          autoFocus
        />
      </View>

      <TouchableOpacity 
        style={[styles.saveBtn, loading && styles.saveBtnDisabled]}
        onPress={handleSave}
        disabled={loading}
      >
        <Text style={styles.saveBtnText}>{loading ? "Guardando..." : "Guardar Almacén"}</Text>
      </TouchableOpacity>
      
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 20,
    gap: 20
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
    marginTop: 10
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
