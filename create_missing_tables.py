import psycopg2

DB_URI = "postgresql://postgres:KAUOTJkFcBSmUADu@db.xzegdfhcxypnffurfvwc.supabase.co:5432/postgres"

def main():
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(DB_URI)
        conn.autocommit = True
        
        create_sql = """
        -- 1. Warehouses
        CREATE TABLE IF NOT EXISTS public.warehouses (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            location TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
        );

        -- 2. Projects
        CREATE TABLE IF NOT EXISTS public.projects (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            description TEXT,
            start_date TEXT,
            end_date TEXT,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
        );

        -- 3. Movements
        CREATE TABLE IF NOT EXISTS public.movements (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
            warehouse_id UUID REFERENCES public.warehouses(id) ON DELETE CASCADE,
            project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
            user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
            type TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
        );

        -- 4. Enable Realtime
        ALTER PUBLICATION supabase_realtime ADD TABLE public.warehouses;
        ALTER PUBLICATION supabase_realtime ADD TABLE public.projects;
        ALTER PUBLICATION supabase_realtime ADD TABLE public.movements;

        -- 5. Enable RLS
        ALTER TABLE public.warehouses ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Permitir todo a autenticados en warehouses" ON public.warehouses FOR ALL TO authenticated USING (true);

        ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Permitir todo a autenticados en projects" ON public.projects FOR ALL TO authenticated USING (true);

        ALTER TABLE public.movements ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Permitir todo a autenticados en movements" ON public.movements FOR ALL TO authenticated USING (true);
        """
        print("Creating missing tables...")
        with conn.cursor() as cur:
            cur.execute(create_sql)
        print("Database tables created successfully!")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
