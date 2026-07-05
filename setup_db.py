import psycopg2
import sys
import os

DB_URI = "postgresql://postgres:KAUOTJkFcBSmUADu@db.xzegdfhcxypnffurfvwc.supabase.co:5432/postgres"

def run_sql_file(conn, filepath):
    if not os.path.exists(filepath):
        print(f"Skipping {filepath}, file not found.")
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    print(f"Executing {os.path.basename(filepath)}...")
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
    print("Done.")

def main():
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(DB_URI)
        print("Connection successful!")
        
        # 1. Schema
        run_sql_file(conn, r"C:\Users\nhuay\.gemini\antigravity-ide\brain\f3e3fb9c-c57b-4c9d-9586-a5c2513bc47d\supabase_schema.sql")
        
        # 2. Trigger
        print("Creating User Trigger...")
        trigger_sql = """
        create or replace function public.handle_new_user()
        returns trigger as $$
        begin
          insert into public.user_profiles (auth_user_id, name, email, role)
          values (new.id, 'Administrador', new.email, 'admin');
          return new;
        end;
        $$ language plpgsql security definer;

        drop trigger if exists on_auth_user_created on auth.users;
        create trigger on_auth_user_created
          after insert on auth.users
          for each row execute procedure public.handle_new_user();
        """
        with conn.cursor() as cur:
            cur.execute(trigger_sql)
        conn.commit()
        print("Trigger created.")
        
        # 3. Migrate data
        run_sql_file(conn, r"e:\databackup\app-inventario-mobil\migracion_excel.sql")

        print("Database setup complete!")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
