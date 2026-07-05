import psycopg2

DB_URI = "postgresql://postgres:KAUOTJkFcBSmUADu@db.xzegdfhcxypnffurfvwc.supabase.co:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URI)
        conn.autocommit = True
        
        insert_sql = """
        INSERT INTO public.warehouses (name, location) 
        VALUES ('Almacén Principal', 'Sede Central')
        ON CONFLICT DO NOTHING;
        
        INSERT INTO public.projects (name, description) 
        VALUES ('Proyecto General', 'Uso general de inventario')
        ON CONFLICT DO NOTHING;
        """
        
        with conn.cursor() as cur:
            cur.execute(insert_sql)
            
        print("Default warehouse and project inserted successfully!")
                
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
