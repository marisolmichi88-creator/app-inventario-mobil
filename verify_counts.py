import psycopg2

DB_URI = "postgresql://postgres:KAUOTJkFcBSmUADu@db.xzegdfhcxypnffurfvwc.supabase.co:5432/postgres"

def main():
    try:
        conn = psycopg2.connect(DB_URI)
        
        tables = ['categories', 'products', 'user_profiles', 'warehouses', 'projects', 'movements']
        
        with conn.cursor() as cur:
            for table in tables:
                cur.execute(f"SELECT COUNT(*) FROM public.{table};")
                count = cur.fetchone()[0]
                print(f"Table '{table}': {count} rows")
                
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
