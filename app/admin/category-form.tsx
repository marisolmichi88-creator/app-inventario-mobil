import { View, Text, StyleSheet, TextInput, TouchableOpacity, Alert } from "react-native";
import { useState, useEffect } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

export default function CategoryFormScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const db = useSQLiteContext();

  const isEditing = !!id;

  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      async function loadCategory() {
        try {
          const cat = await db.getFirstAsync<{name: string}>(
            "SELECT name FROM categories WHERE id = ?", [id as string]
          );
          if (cat) {
            setName(cat.name);
          }
        } catch (e) {
          console.error("Error loading category", e);
        }
      }
      loadCategory();
    }
  }, [id, db]);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert("Error", "El nombre de la categoría no puede estar vacío.");
      return;
    }

    setLoading(true);
    try {
      if (isEditing) {
        await db.runAsync(
          "UPDATE categories SET name = ?, sync_status = 'pending' WHERE id = ?",
          [name.trim(), id as string]
        );
      } else {
        const newId = `cat-${Date.now()}`;
        await db.runAsync(
          "INSERT INTO categories (id, name, sync_status) VALUES (?, ?, 'pending')",
          [newId, name.trim()]
        );
      }
      router.back();
    } catch (e: any) {
      console.error("Error saving category", e);
      Alert.alert("Error", "No se pudo guardar la categoría.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      
      <View style={styles.formGroup}>
        <Text style={styles.label}>Nombre de la Categoría *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. Herramientas eléctricas"
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
        <Text style={styles.saveBtnText}>{loading ? "Guardando..." : "Guardar Categoría"}</Text>
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
