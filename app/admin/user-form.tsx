import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert } from "react-native";
import { useState, useEffect } from "react";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

export default function UserFormScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const db = useSQLiteContext();

  const isEditing = !!id;

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("Operario");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      async function loadUser() {
        try {
          const user = await db.getFirstAsync<{name: string, email: string, role: string, password: string}>(
            "SELECT name, email, role, password FROM users WHERE id = ?", [id as string]
          );
          if (user) {
            setName(user.name);
            setEmail(user.email);
            setRole(user.role);
            setPassword(user.password);
          }
        } catch (e) {
          console.error("Error loading user", e);
        }
      }
      loadUser();
    }
  }, [id, db]);

  const handleSave = async () => {
    if (!name || !email || !password) {
      Alert.alert("Error", "Por favor completa todos los campos requeridos.");
      return;
    }

    setLoading(true);
    try {
      if (isEditing) {
        await db.runAsync(
          "UPDATE users SET name = ?, email = ?, password = ?, role = ?, sync_status = 'pending' WHERE id = ?",
          [name, email, password, role, id as string]
        );
      } else {
        const newId = `usr-${Date.now()}`;
        await db.runAsync(
          "INSERT INTO users (id, name, email, password, role, active, sync_status) VALUES (?, ?, ?, ?, ?, 1, 'pending')",
          [newId, name, email, password, role]
        );
      }
      router.back();
    } catch (e: any) {
      console.error("Error saving user", e);
      Alert.alert("Error", "No se pudo guardar el usuario. Puede que el correo ya exista.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      
      <View style={styles.formGroup}>
        <Text style={styles.label}>Nombre completo *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ej. Juan Pérez"
          value={name}
          onChangeText={setName}
        />
      </View>

      <View style={styles.formGroup}>
        <Text style={styles.label}>Correo electrónico *</Text>
        <TextInput 
          style={styles.input}
          placeholder="ejemplo@proenergim.com"
          keyboardType="email-address"
          autoCapitalize="none"
          value={email}
          onChangeText={setEmail}
        />
      </View>

      <View style={styles.formGroup}>
        <Text style={styles.label}>Contraseña *</Text>
        <TextInput 
          style={styles.input}
          placeholder="Mínimo 6 caracteres"
          secureTextEntry
          value={password}
          onChangeText={setPassword}
        />
      </View>

      <View style={styles.formGroup}>
        <Text style={styles.label}>Rol *</Text>
        <View style={styles.rolesRow}>
          <TouchableOpacity 
            style={[styles.roleBtn, role === "Admin" && styles.roleActive]}
            onPress={() => setRole("Admin")}
          >
            <Text style={[styles.roleBtnText, role === "Admin" && styles.roleActiveText]}>Administrador</Text>
          </TouchableOpacity>
          <TouchableOpacity 
            style={[styles.roleBtn, role === "Operario" && styles.roleActive]}
            onPress={() => setRole("Operario")}
          >
            <Text style={[styles.roleBtnText, role === "Operario" && styles.roleActiveText]}>Operario</Text>
          </TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity 
        style={[styles.saveBtn, loading && styles.saveBtnDisabled]}
        onPress={handleSave}
        disabled={loading}
      >
        <Text style={styles.saveBtnText}>{loading ? "Guardando..." : "Guardar Usuario"}</Text>
      </TouchableOpacity>
      
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
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
  rolesRow: {
    flexDirection: "row",
    gap: 12
  },
  roleBtn: {
    flex: 1,
    padding: 12,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    alignItems: "center",
    backgroundColor: colors.surface
  },
  roleActive: {
    borderColor: colors.primary,
    backgroundColor: '#E5F1FF'
  },
  roleBtnText: {
    fontSize: 14,
    fontWeight: "600",
    color: colors.muted
  },
  roleActiveText: {
    color: colors.primary
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
