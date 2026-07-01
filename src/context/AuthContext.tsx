import React, { createContext, useContext, useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useSQLiteContext } from "expo-sqlite";
import { router } from "expo-router";

type User = {
  id: string;
  name: string;
  email: string;
  role: string;
};

type AuthContextType = {
  user: User | null;
  isLoading: boolean;
  signIn: (email: string, pass: string) => Promise<{ success: boolean; error?: string }>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const db = useSQLiteContext();

  useEffect(() => {
    // Check if user session exists in AsyncStorage
    async function loadSession() {
      try {
        const storedUser = await AsyncStorage.getItem("userSession");
        if (storedUser) {
          setUser(JSON.parse(storedUser));
        }
      } catch (e) {
        console.error("Error loading session", e);
      } finally {
        setIsLoading(false);
      }
    }
    loadSession();
  }, []);

  const signIn = async (email: string, pass: string) => {
    try {
      // Consultar usuario en la base de datos
      const result = await db.getFirstAsync<{ id: string; name: string; email: string; role: string; active: number }>(
        "SELECT id, name, email, role, active FROM users WHERE email = ? AND password = ?",
        [email.trim().toLowerCase(), pass]
      );

      if (result) {
        if (result.active === 0) {
          return { success: false, error: "Este usuario se encuentra desactivado." };
        }

        const sessionUser = {
          id: result.id,
          name: result.name,
          email: result.email,
          role: result.role,
        };

        // Guardar sesión
        await AsyncStorage.setItem("userSession", JSON.stringify(sessionUser));
        setUser(sessionUser);
        
        // Redirigir al dashboard
        router.replace("/(tabs)/dashboard");
        return { success: true };
      } else {
        return { success: false, error: "Correo o contraseña incorrectos." };
      }
    } catch (e) {
      console.error("Login error", e);
      return { success: false, error: "Ocurrió un error al intentar iniciar sesión." };
    }
  };

  const signOut = async () => {
    await AsyncStorage.removeItem("userSession");
    setUser(null);
    router.replace("/login");
  };

  return (
    <AuthContext.Provider value={{ user, isLoading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
