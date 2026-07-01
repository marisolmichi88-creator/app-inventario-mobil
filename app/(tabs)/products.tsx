import { FlatList, StyleSheet, Text, TextInput, View, TouchableOpacity, ScrollView } from "react-native";
import { useMemo, useState, useCallback } from "react";
import { useSQLiteContext } from "expo-sqlite";
import { useLocalSearchParams, useRouter, useFocusEffect } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

import { ProductRow } from "@/components/ProductRow";
import { colors } from "@/theme/colors";
import { Product } from "@/types/inventory";

export default function ProductsScreen() {
  const router = useRouter();
  const { filter } = useLocalSearchParams<{ filter?: string }>();
  
  const [query, setQuery] = useState("");
  const [products, setProducts] = useState<Product[]>([]);
  const [warehouses, setWarehouses] = useState<string[]>([]);
  const [activeFilter, setActiveFilter] = useState<"all" | "low_stock">("all");
  const [selectedWarehouse, setSelectedWarehouse] = useState<string | null>(null);
  const db = useSQLiteContext();

  // Sync initial param filter
  useFocusEffect(
    useCallback(() => {
      if (filter === "low_stock") {
        setActiveFilter("low_stock");
      }
    }, [filter])
  );

  useFocusEffect(
    useCallback(() => {
      let isActive = true;
      async function fetchProducts() {
        try {
          const allProducts = await db.getAllAsync<Product>(
            "SELECT id, name, category_id as category, warehouse_id as warehouse, barcode, unit, stock, min_stock as minStock, currency, unit_cost as unitCost FROM products"
          );
          const uniqueWarehouses = await db.getAllAsync<{warehouse: string}>(
            "SELECT DISTINCT warehouse_id as warehouse FROM products WHERE warehouse_id IS NOT NULL AND warehouse_id != ''"
          );
          if (isActive) {
            setProducts(allProducts);
            setWarehouses(uniqueWarehouses.map(w => w.warehouse).filter(Boolean));
          }
        } catch (error) {
          console.error("Error fetching products:", error);
        }
      }
      fetchProducts();
      return () => { isActive = false; };
    }, [db])
  );

  const filteredProducts = useMemo(() => {
    let result = products;
    
    // Apply low stock filter
    if (activeFilter === "low_stock") {
      result = result.filter(p => p.stock <= p.minStock);
    }

    // Apply warehouse filter
    if (selectedWarehouse) {
      result = result.filter(p => p.warehouse === selectedWarehouse);
    }
    
    // Apply search query
    const value = query.trim().toLowerCase();
    if (value) {
      result = result.filter((product) =>
        [product.name, product.category, product.warehouse, product.barcode].some((field) =>
          field?.toLowerCase().includes(value)
        )
      );
    }
    
    return result;
  }, [query, products, activeFilter, selectedWarehouse]);

  return (
    <View style={styles.screen}>
      <TextInput
        placeholder="Buscar producto, almacen o codigo"
        placeholderTextColor={colors.muted}
        value={query}
        onChangeText={setQuery}
        style={styles.search}
      />
      
      <View style={styles.filtersRow}>
        <TouchableOpacity 
          style={[styles.filterPill, activeFilter === "all" && styles.filterPillActive]}
          onPress={() => setActiveFilter("all")}
        >
          <Text style={[styles.filterText, activeFilter === "all" && styles.filterTextActive]}>Todos</Text>
        </TouchableOpacity>
        <TouchableOpacity 
          style={[styles.filterPill, activeFilter === "low_stock" && styles.filterPillActiveLow]}
          onPress={() => setActiveFilter("low_stock")}
        >
          <Text style={[styles.filterText, activeFilter === "low_stock" && styles.filterTextActiveLow]}>Stock Bajo</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.warehouseScrollContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.warehouseRow}>
          <TouchableOpacity 
            style={[styles.filterPill, selectedWarehouse === null && styles.filterPillActive]}
            onPress={() => setSelectedWarehouse(null)}
          >
            <Text style={[styles.filterText, selectedWarehouse === null && styles.filterTextActive]}>Todos los Almacenes</Text>
          </TouchableOpacity>
          {warehouses.map(w => (
            <TouchableOpacity 
              key={w}
              style={[styles.filterPill, selectedWarehouse === w && styles.filterPillActive]}
              onPress={() => setSelectedWarehouse(w)}
            >
              <Text style={[styles.filterText, selectedWarehouse === w && styles.filterTextActive]}>{w.trim()}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <FlatList
        data={filteredProducts}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity onPress={() => router.push({ pathname: "/admin/product-form", params: { id: item.id } })}>
            <ProductRow product={item} />
          </TouchableOpacity>
        )}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>No se encontraron productos.</Text>}
      />

      <TouchableOpacity 
        style={styles.fab}
        onPress={() => router.push("/admin/product-form")}
      >
        <Ionicons name="add" size={30} color="white" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 16
  },
  search: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: 8,
    borderWidth: 1,
    color: colors.text,
    fontSize: 15,
    paddingHorizontal: 14,
    paddingVertical: 12
  },
  filtersRow: {
    flexDirection: "row",
    gap: 10,
    marginBottom: 12
  },
  warehouseScrollContainer: {
    marginBottom: 16
  },
  warehouseRow: {
    gap: 10,
    paddingRight: 16
  },
  filterPill: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border
  },
  filterPillActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary
  },
  filterPillActiveLow: {
    backgroundColor: colors.danger,
    borderColor: colors.danger
  },
  filterText: {
    color: colors.text,
    fontSize: 14,
    fontWeight: "600"
  },
  filterTextActive: {
    color: "white"
  },
  filterTextActiveLow: {
    color: "white"
  },
  list: {
    gap: 10,
    paddingBottom: 24
  },
  empty: {
    color: colors.muted,
    marginTop: 24,
    textAlign: "center"
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
  }
});
