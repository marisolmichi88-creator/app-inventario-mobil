import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert } from "react-native";
import { useState, useCallback } from "react";
import { useFocusEffect, useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

type Category = {
  id: string;
  name: string;
};

export default function CategoriesScreen() {
  const db = useSQLiteContext();
  const router = useRouter();
  const [categories, setCategories] = useState<Category[]>([]);

  useFocusEffect(
    useCallback(() => {
      let isActive = true;
      async function fetchCategories() {
        try {
          const result = await db.getAllAsync<Category>("SELECT id, name FROM categories ORDER BY name ASC");
          if (isActive) setCategories(result);
        } catch (error) {
          console.error("Error fetching categories", error);
        }
      }
      fetchCategories();
      return () => { isActive = false; };
    }, [db])
  );

  const deleteCategory = (id: string) => {
    Alert.alert(
      "Eliminar Categoría",
      "¿Estás seguro de que deseas eliminar esta categoría? Esta acción no se puede deshacer.",
      [
        { text: "Cancelar", style: "cancel" },
        { 
          text: "Eliminar", 
          style: "destructive",
          onPress: async () => {
            try {
              await db.runAsync("DELETE FROM categories WHERE id = ?", [id]);
              setCategories(categories.filter(c => c.id !== id));
            } catch (e) {
              console.error("Error deleting category", e);
              Alert.alert("Error", "No se pudo eliminar la categoría.");
            }
          }
        }
      ]
    );
  };

  const renderItem = ({ item }: { item: Category }) => (
    <View style={styles.card}>
      <View style={styles.info}>
        <Ionicons name="pricetag-outline" size={20} color={colors.primary} style={{marginRight: 10}} />
        <Text style={styles.name}>{item.name}</Text>
      </View>
      
      <View style={styles.actions}>
        <TouchableOpacity 
          style={styles.actionBtn}
          onPress={() => router.push({ pathname: "/admin/category-form", params: { id: item.id } })}
        >
          <Ionicons name="pencil" size={20} color={colors.primary} />
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={styles.actionBtn}
          onPress={() => deleteCategory(item.id)}
        >
          <Ionicons name="trash" size={20} color={colors.danger} />
        </TouchableOpacity>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={categories}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>No hay categorías registradas</Text>}
      />

      <TouchableOpacity 
        style={styles.fab}
        onPress={() => router.push("/admin/category-form")}
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
