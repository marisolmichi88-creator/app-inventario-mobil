import { StyleSheet, Text, View } from "react-native";

import { colors } from "@/theme/colors";

type StatCardProps = {
  label: string;
  value: string;
  tone?: "default" | "warning";
};

export function StatCard({ label, value, tone = "default" }: StatCardProps) {
  return (
    <View style={[styles.card, tone === "warning" && styles.warning]}>
      <Text style={styles.value}>{value}</Text>
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderRadius: 8,
    borderWidth: 1,
    flex: 1,
    padding: 16
  },
  warning: {
    borderColor: colors.warning
  },
  value: {
    color: colors.text,
    fontSize: 26,
    fontWeight: "800"
  },
  label: {
    color: colors.muted,
    fontSize: 13,
    marginTop: 4
  }
});
