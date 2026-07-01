import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert } from "react-native";
import { useState, useCallback } from "react";
import { useFocusEffect, useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

type Project = {
  id: string;
  name: string;
  client: string;
};

export default function ProjectsScreen() {
  const db = useSQLiteContext();
  const router = useRouter();
  const [projects, setProjects] = useState<Project[]>([]);

  useFocusEffect(
    useCallback(() => {
      let isActive = true;
      async function fetchProjects() {
        try {
          const result = await db.getAllAsync<Project>("SELECT id, name, client FROM projects ORDER BY name ASC");
          if (isActive) setProjects(result);
        } catch (error) {
          console.error("Error fetching projects", error);
        }
      }
      fetchProjects();
      return () => { isActive = false; };
    }, [db])
  );

  const deleteProject = (id: string) => {
    Alert.alert(
      "Eliminar Proyecto",
      "¿Estás seguro de que deseas eliminar este proyecto? Esta acción no se puede deshacer.",
      [
        { text: "Cancelar", style: "cancel" },
        { 
          text: "Eliminar", 
          style: "destructive",
          onPress: async () => {
            try {
              await db.runAsync("DELETE FROM projects WHERE id = ?", [id]);
              setProjects(projects.filter(p => p.id !== id));
            } catch (e) {
              console.error("Error deleting project", e);
              Alert.alert("Error", "No se pudo eliminar el proyecto.");
            }
          }
        }
      ]
    );
  };

  const renderItem = ({ item }: { item: Project }) => (
    <View style={styles.card}>
      <View style={styles.info}>
        <Ionicons name="briefcase-outline" size={20} color={colors.primary} style={{marginRight: 10}} />
        <View style={{ flex: 1 }}>
          <Text style={styles.name}>{item.name}</Text>
          <Text style={styles.meta}>Cliente: {item.client || "N/A"}</Text>
        </View>
      </View>
      
      <View style={styles.actions}>
        <TouchableOpacity 
          style={styles.actionBtn}
          onPress={() => router.push({ pathname: "/admin/project-form", params: { id: item.id } })}
        >
          <Ionicons name="pencil" size={20} color={colors.primary} />
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={styles.actionBtn}
          onPress={() => deleteProject(item.id)}
        >
          <Ionicons name="trash" size={20} color={colors.danger} />
        </TouchableOpacity>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={projects}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>No hay proyectos registrados</Text>}
      />

      <TouchableOpacity 
        style={styles.fab}
        onPress={() => router.push("/admin/project-form")}
      >
        <Ionicons name="add" size={30} color="white" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  list: {
    padding: 16,
    gap: 12
  },
  card: {
    backgroundColor: colors.surface,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between"
  },
  info: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1
  },
  name: {
    fontSize: 16,
    fontWeight: "700",
    color: colors.text
  },
  meta: {
    fontSize: 13,
    color: colors.muted,
    marginTop: 4
  },
  actions: {
    flexDirection: "row",
    gap: 8
  },
  actionBtn: {
    padding: 8,
    backgroundColor: colors.background,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border
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
  },
  empty: {
    textAlign: "center",
    color: colors.muted,
    marginTop: 40
  }
});
