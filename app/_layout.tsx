import { Stack, useRouter, useSegments } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useEffect, useState } from "react";
import * as SplashScreen from "expo-splash-screen";
import { SQLiteProvider } from "expo-sqlite";
import { initDatabase } from "@/services/database";
import { AuthProvider, useAuth } from "@/context/AuthContext";

SplashScreen.preventAutoHideAsync();

function RootLayoutNav() {
  const { user, isLoading: authLoading } = useAuth();
  const [isReady, setReady] = useState(false);
  const segments = useSegments();
  const router = useRouter();

  // Proteger rutas
  useEffect(() => {
    if (authLoading) return;

    const inAuthGroup = segments[0] === "login";

    if (!user && !inAuthGroup) {
      router.replace("/login");
    } else if (user && inAuthGroup) {
      router.replace("/(tabs)/dashboard");
    }
  }, [user, authLoading, segments]);

  useEffect(() => {
    if (!authLoading) {
      setTimeout(() => {
        setReady(true);
        SplashScreen.hideAsync();
      }, 100);
    }
  }, [authLoading]);

  if (!isReady) {
    return null;
  }

  return (
    <>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="login" options={{ headerShown: false }} />
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack>
      <StatusBar style="dark" />
    </>
  );
}

export default function RootLayout() {
  return (
    <SQLiteProvider databaseName=":memory:" onInit={initDatabase}>
      <AuthProvider>
        <RootLayoutNav />
      </AuthProvider>
    </SQLiteProvider>
  );
}
