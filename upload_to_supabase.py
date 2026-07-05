import pandas as pd
import uuid
import math

def clean_float(val):
    if pd.isna(val): return 0.0
    return float(val)

def clean_int(val):
    if pd.isna(val): return 0
    return int(val)

def main():
    print("Leyendo Excel para generar script SQL...")
    try:
        df = pd.read_excel('bd.xlsx')
    except Exception as e:
        print(f"Error reading Excel: {e}")
        return

    sql_lines = []
    sql_lines.append("-- ==========================================")
    sql_lines.append("-- SCRIPT DE MIGRACIÓN DE EXCEL A SUPABASE")
    sql_lines.append("-- ==========================================\n")

    # 1. Categorías
    categorias_unicas = df['TIPO'].dropna().unique()
    cat_map = {} 
    
    sql_lines.append("-- 1. Insertar Categorías")
    for tipo in categorias_unicas:
        cat_id = str(uuid.uuid4())
        cat_map[tipo] = cat_id
        # Escape single quotes
        tipo_clean = str(tipo).replace("'", "''")
        sql_lines.append(f"INSERT INTO public.categories (id, name) VALUES ('{cat_id}', '{tipo_clean}');")
        
    sql_lines.append("\n-- 2. Insertar Productos")
    
    for index, row in df.iterrows():
        prod_id = str(uuid.uuid4())
        
        item = str(row['ITEM']) if not pd.isna(row['ITEM']) else str(index)
        code = f"PROD-{item.zfill(4)}"
        
        name = str(row['PRODUCTO']) if not pd.isna(row['PRODUCTO']) else "Sin Nombre"
        name = name.replace("'", "''")
        
        tipo = row['TIPO']
        category_id = cat_map.get(tipo, None)
        category_sql = f"'{category_id}'" if category_id else "NULL"
        
        stock = clean_int(row['UND'])
        cost = clean_float(row['CU'])
        
        desc = f"Unidad: {row.get('UM', '')} | Moneda: {row.get('MONEDA', '')}".replace("'", "''")
        
        sql = f"INSERT INTO public.products (id, code, name, description, price, cost, stock, min_stock, category_id, is_active) " \
              f"VALUES ('{prod_id}', '{code}', '{name}', '{desc}', {cost}, {cost}, {stock}, 0, {category_sql}, true);"
        sql_lines.append(sql)

    with open("migracion_excel.sql", "w", encoding="utf-8") as f:
        f.write("\n".join(sql_lines))
        
    print(f"¡Éxito! Se ha generado el archivo 'migracion_excel.sql' con {len(categorias_unicas)} categorías y {len(df)} productos.")

if __name__ == "__main__":
    main()
