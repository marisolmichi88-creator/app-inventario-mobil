import { View, Text, StyleSheet, TouchableOpacity } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/theme/colors";

export default function AdminScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Panel de Administración</Text>
      
      <View style={styles.menu}>
        <TouchableOpacity style={styles.menuItem} onPress={() => router.push("/admin/users")}>
          <View style={styles.iconBox}>
            <Ionicons name="people" size={24} color={colors.primary} />
          </View>
          <View style={styles.itemText}>
            <Text style={styles.itemTitle}>Usuarios</Text>
            <Text style={styles.itemDesc}>Gestionar roles y accesos</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.muted} />
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push("/admin/categories")}>
          <View style={styles.iconBox}>
            <Ionicons name="pricetags" size={24} color={colors.primary} />
          </View>
          <View style={styles.itemText}>
            <Text style={styles.itemTitle}>Categorías</Text>
            <Text style={styles.itemDesc}>Gestionar familias de productos</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.muted} />
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push("/admin/projects")}>
          <View style={styles.iconBox}>
            <Ionicons name="briefcase" size={24} color={colors.primary} />
          </View>
          <View style={styles.itemText}>
            <Text style={styles.itemTitle}>Proyectos</Text>
            <Text style={styles.itemDesc}>Administrar catálogo de destinos</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.muted} />
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push("/admin/warehouses")}>
          <View style={styles.iconBox}>
            <Ionicons name="business" size={24} color={colors.primary} />
          </View>
          <View style={styles.itemText}>
            <Text style={styles.itemTitle}>Almacenes</Text>
            <Text style={styles.itemDesc}>Gestionar ubicaciones físicas</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.muted} />
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 20
  },
  title: {
    fontSize: 22,
    fontWeight: "bold",
    color: colors.text,
    marginBottom: 20
  },
  menu: {
    gap: 15
  },
  menuItem: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.surface,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border
  },
  iconBox: {
    backgroundColor: '#E5F1FF',
    padding: 10,
    borderRadius: 8,
    marginRight: 15
  },
  itemText: {
    flex: 1
  },
  itemTitle: {
    fontSize: 16,
    fontWeight: "600",
    color: colors.text
  },
  itemDesc: {
    fontSize: 13,
    color: colors.muted,
    marginTop: 2
  }
});
