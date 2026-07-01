import { View, Text, StyleSheet, TextInput, TouchableOpacity, Alert } from "react-native";
import { useState, useEffect } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

export default function ProjectFormScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const db = useSQLiteContext();

  const isEditing = !!id;

  const [name, setName] = useState("");
  const [client, setClient] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      async function loadProject() {
        try {
          const proj = await db.getFirstAsync<{name: string, client: string}>(
            "SELECT name, client FROM projects WHERE id = ?", [id as string]
          );
          if (proj) {
            setName(proj.name);
            setClient(proj.client || "");
          }
        } catch (e) {
          console.error("Error loading project", e);
        }
      }
      loadProject();
    }
  }, [id, db]);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert("Error", "El nombre del proyecto no puede estar vacío.");
      return;
    }

    setLoading(true);
    try {
      if (isEditing) {
        await db.runAsync(
          "UPDATE projects SET name = ?, client = ?, sync_status = 'pending' WHERE id = ?",
          [name.trim(), client.trim(), id as string]
        );
      } else {
        const newId = `proj-${Date.now()}`;
        await db.runAsync(
          "INSERT INTO projects (id, name, client, sync_status) VALUES (?, ?, ?, 'pending')",
          [newId, name.trim(), client.trim()]
        );
      }
      router.back();
    } catch (e: any) {
      console.error("Error saving project", e);
      Alert.alert("Error", "No se pudo guardar el proyecto.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      
      <View style={styles.formGroup}>
        <Text style={styles.label}>Nombre del Proyecto *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. Instalación Torre 1"
          value={name}
          onChangeText={setName}
          autoFocus
        />
      </View>
      
      <View style={styles.formGroup}>
        <Text style={styles.label}>Cliente</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. Empresa Constructora S.A."
          value={client}
          onChangeText={setClient}
        />
      </View>

      <TouchableOpacity 
        style={[styles.saveBtn, loading && styles.saveBtnDisabled]}
        onPress={handleSave}
        disabled={loading}
      >
        <Text style={styles.saveBtnText}>{loading ? "Guardando..." : "Guardar Proyecto"}</Text>
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
