import { ScrollView, StyleSheet, Text, View, TouchableOpacity } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter, useFocusEffect } from "expo-router";
import { useState, useCallback } from "react";
import { useSQLiteContext } from "expo-sqlite";

import { StatCard } from "@/components/StatCard";
import { colors } from "@/theme/colors";
import { useAuth } from "@/context/AuthContext";

export default function DashboardScreen() {
  const { signOut } = useAuth();
  const router = useRouter();
  const db = useSQLiteContext();
  
  const [stats, setStats] = useState({ products: 0, totalStock: 0, lowStock: 0, projects: 0 });
  const [movements, setMovements] = useState<any[]>([]);

  useFocusEffect(
    useCallback(() => {
      let isActive = true;
      async function loadData() {
        try {
          const prodCount = await db.getFirstAsync<{count: number}>("SELECT COUNT(*) as count FROM products");
          const stockSum = await db.getFirstAsync<{total: number}>("SELECT SUM(stock) as total FROM products");
          const lowCount = await db.getFirstAsync<{count: number}>("SELECT COUNT(*) as count FROM products WHERE stock <= min_stock");
          const projCount = await db.getFirstAsync<{count: number}>("SELECT COUNT(*) as count FROM projects");

          if (!isActive) return;

          setStats({
            products: prodCount?.count || 0,
            totalStock: stockSum?.total || 0,
            lowStock: lowCount?.count || 0,
            projects: projCount?.count || 0,
          });

          // Load recent movements (limit 4)
          const recent = await db.getAllAsync<{id: string, type: string, quantity: number, productName: string, project: string}>(
            `SELECT m.id, m.type, m.quantity, p.name as productName, pr.name as project 
             FROM movements m
             LEFT JOIN products p ON m.product_id = p.id
             LEFT JOIN projects pr ON m.project_id = pr.id
             ORDER BY m.date DESC LIMIT 4`
          );
          
          if (isActive) setMovements(recent);
        } catch (e) {
          console.warn("Error loading dashboard data", e);
        }
      }
      
      loadData();
      return () => { isActive = false; };
    }, [db])
  );

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <View style={styles.headerRow}>
        <View>
          <Text style={styles.kicker}>Proenergim E.I.R.L.</Text>
          <Text style={styles.title}>Inventario movil</Text>
        </View>
        <View style={styles.actionsRow}>
          <TouchableOpacity onPress={() => router.push("/admin")} style={styles.adminBtn}>
            <Ionicons name="settings-outline" size={24} color={colors.primary} />
          </TouchableOpacity>
          <TouchableOpacity onPress={signOut} style={styles.logoutBtn}>
            <Ionicons name="log-out-outline" size={24} color={colors.danger} />
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.grid}>
        <TouchableOpacity style={styles.cardWrapper} onPress={() => router.push("/products")}>
          <StatCard label="Productos" value={stats.products.toString()} />
        </TouchableOpacity>
        
        <View style={styles.cardWrapper}>
          <StatCard label="Stock total" value={Number(stats.totalStock || 0).toFixed(0)} />
        </View>

        <TouchableOpacity style={styles.cardWrapper} onPress={() => router.push({ pathname: "/products", params: { filter: "low_stock" } })}>
          <StatCard label="Stock bajo" value={stats.lowStock.toString()} tone="warning" />
        </TouchableOpacity>

        <TouchableOpacity style={styles.cardWrapper} onPress={() => router.push("/admin/projects")}>
          <StatCard label="Proyectos" value={stats.projects.toString()} />
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Movimientos recientes</Text>
        {movements.length === 0 && <Text style={styles.meta}>No hay movimientos registrados.</Text>}
        {movements.map((movement) => (
          <View key={movement.id} style={styles.movement}>
            <View>
              <Text style={styles.product}>{movement.productName || 'Producto Eliminado'}</Text>
              <Text style={styles.meta}>{movement.project || 'General'}</Text>
            </View>
            <Text style={movement.type === "entrada" ? styles.in : styles.out}>
              {movement.type === "entrada" ? "+" : "-"}
              {movement.quantity}
            </Text>
          </View>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background
  },
  content: {
    gap: 20,
    padding: 20
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 10
  },
  adminBtn: {
    padding: 8,
    backgroundColor: '#E5F1FF',
    borderRadius: 8,
  },
  logoutBtn: {
    padding: 8,
    backgroundColor: '#FFE5E5',
    borderRadius: 8,
  },
  kicker: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: "700",
    textTransform: "uppercase"
  },
  title: {
    color: colors.text,
    fontSize: 28,
    fontWeight: "800",
    marginTop: 4
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12
  },
  cardWrapper: {
    flexBasis: "47%",
    flexGrow: 1,
  },
  section: {
    gap: 10
  },
  sectionTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: "700"
  },
  movement: {
    alignItems: "center",
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    padding: 14
  },
  product: {
    color: colors.text,
    fontSize: 15,
    fontWeight: "700"
  },
  meta: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 3
  },
  in: {
    color: colors.success,
    fontSize: 17,
    fontWeight: "800"
  },
  out: {
    color: colors.danger,
    fontSize: 17,
    fontWeight: "800"
  }
});
