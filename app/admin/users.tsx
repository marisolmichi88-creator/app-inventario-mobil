import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert } from "react-native";
import { useState, useCallback } from "react";
import { useFocusEffect, useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useSQLiteContext } from "expo-sqlite";

import { colors } from "@/theme/colors";

type User = {
  id: string;
  name: string;
  email: string;
  role: string;
  active: number;
};

export default function UsersScreen() {
  const db = useSQLiteContext();
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);

  useFocusEffect(
    useCallback(() => {
      let isActive = true;
      async function fetchUsers() {
        try {
          const result = await db.getAllAsync<User>("SELECT id, name, email, role, active FROM users ORDER BY name ASC");
          if (isActive) setUsers(result);
        } catch (error) {
          console.error("Error fetching users", error);
        }
      }
      fetchUsers();
      return () => { isActive = false; };
    }, [db])
  );

  const toggleStatus = async (user: User) => {
    try {
      const newStatus = user.active === 1 ? 0 : 1;
      await db.runAsync("UPDATE users SET active = ?, sync_status = 'pending' WHERE id = ?", [newStatus, user.id]);
      setUsers(users.map(u => u.id === user.id ? { ...u, active: newStatus } : u));
    } catch (e) {
      console.error("Error updating user status", e);
    }
  };

  const renderItem = ({ item }: { item: User }) => (
    <View style={[styles.card, item.active === 0 && styles.inactiveCard]}>
      <View style={styles.info}>
        <Text style={styles.name}>{item.name}</Text>
        <Text style={styles.email}>{item.email}</Text>
        <View style={styles.badges}>
          <Text style={styles.roleBadge}>{item.role}</Text>
          <Text style={[styles.statusBadge, item.active ? styles.statusActive : styles.statusInactive]}>
            {item.active ? "Activo" : "Inactivo"}
          </Text>
        </View>
      </View>
      
      <View style={styles.actions}>
        <TouchableOpacity 
          style={styles.actionBtn}
          onPress={() => router.push({ pathname: "/admin/user-form", params: { id: item.id } })}
        >
          <Ionicons name="pencil" size={20} color={colors.primary} />
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={styles.actionBtn}
          onPress={() => toggleStatus(item)}
        >
          <Ionicons name={item.active ? "eye-off" : "eye"} size={20} color={item.active ? colors.warning : colors.success} />
        </TouchableOpacity>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={users}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>No hay usuarios registrados</Text>}
      />

      <TouchableOpacity 
        style={styles.fab}
        onPress={() => router.push("/admin/user-form")}
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
    alignItems: "center"
  },
  inactiveCard: {
    opacity: 0.6
  },
  info: {
    flex: 1
  },
  name: {
    fontSize: 16,
    fontWeight: "700",
    color: colors.text
  },
  email: {
    fontSize: 13,
    color: colors.muted,
    marginTop: 2
  },
  badges: {
    flexDirection: "row",
    gap: 8,
    marginTop: 8
  },
  roleBadge: {
    backgroundColor: '#E5F1FF',
    color: colors.primary,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    fontSize: 11,
    fontWeight: "bold",
    overflow: "hidden"
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    fontSize: 11,
    fontWeight: "bold",
    overflow: "hidden"
  },
  statusActive: {
    backgroundColor: '#E8F5E9',
    color: colors.success
  },
  statusInactive: {
    backgroundColor: '#FFF3E0',
    color: colors.warning
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
