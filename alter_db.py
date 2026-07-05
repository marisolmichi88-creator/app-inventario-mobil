import psycopg2
import sys

DB_URI = "postgresql://postgres:KAUOTJkFcBSmUADu@db.xzegdfhcxypnffurfvwc.supabase.co:5432/postgres"

def main():
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(DB_URI)
        print("Connection successful!")
        
        alter_sql = """
        ALTER TABLE public.products ADD COLUMN IF NOT EXISTS serial_number TEXT UNIQUE;
        ALTER TABLE public.products ADD COLUMN IF NOT EXISTS unit TEXT;
        ALTER TABLE public.products ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'PEN';
        """
        print("Altering products table...")
        with conn.cursor() as cur:
            cur.execute(alter_sql)
        conn.commit()
        print("Database alter complete!")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
