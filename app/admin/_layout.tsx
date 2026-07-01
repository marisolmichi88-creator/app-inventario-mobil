import { Stack } from "expo-router";

export default function AdminLayout() {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ title: "Administración" }} />
      <Stack.Screen name="users" options={{ title: "Usuarios" }} />
      <Stack.Screen name="user-form" options={{ title: "Usuario", presentation: "modal" }} />
      <Stack.Screen name="categories" options={{ title: "Categorías" }} />
      <Stack.Screen name="category-form" options={{ title: "Categoría", presentation: "modal" }} />
      <Stack.Screen name="warehouses" options={{ title: "Almacenes" }} />
      <Stack.Screen name="warehouse-form" options={{ title: "Almacén", presentation: "modal" }} />
      <Stack.Screen name="product-form" options={{ title: "Producto", presentation: "modal" }} />
      <Stack.Screen name="movement-form" options={{ title: "Registrar Movimiento", presentation: "modal" }} />
      <Stack.Screen name="projects" options={{ title: "Proyectos" }} />
      <Stack.Screen name="project-form" options={{ title: "Proyecto", presentation: "modal" }} />
    </Stack>
  );
}
