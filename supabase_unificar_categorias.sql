-- ============================================================================
-- UNIFICAR CATEGORIAS DUPLICADAS  (Supabase > SQL Editor)
--
-- Junta las categorias que solo se diferencian por mayusculas, tildes o
-- espacios. De cada grupo sobrevive la que MAS productos tiene; el resto se
-- borra despues de reasignarle sus productos a la ganadora.
--
-- Ejecuta un bloque a la vez. Cada Run es una transaccion propia, por eso el
-- begin y el commit del PASO 2 van juntos en la misma ejecucion.
-- ============================================================================


-- PASO 0 — VER los duplicados. Solo lectura.
with norm as (
  select id, name,
         regexp_replace(
           translate(lower(btrim(name)),
                     'áàäâãéèëêíìïîóòöôõúùüûñç',
                     'aaaaaeeeeiiiiooooouuuunc'),
           '\s+', ' ', 'g') as clave
    from public.categories
),
grupos as (
  select clave from norm group by clave having count(*) > 1
)
select n.clave as nombre_unificado,
       n.name  as nombre_actual,
       (select count(*) from public.products p where p.category_id = n.id)
         as productos,
       n.id
  from norm n
  join grupos g on g.clave = n.clave
 order by n.clave,
          (select count(*) from public.products p where p.category_id = n.id) desc,
          n.name;


-- PASO 1 — COMPROBAR que nada mas depende de categories.
-- Deberia salir solo products.category_id.
select tc.table_name   as tabla_que_apunta,
       kcu.column_name as columna
  from information_schema.table_constraints tc
  join information_schema.key_column_usage kcu
    on kcu.constraint_name = tc.constraint_name
  join information_schema.constraint_column_usage ccu
    on ccu.constraint_name = tc.constraint_name
 where tc.constraint_type = 'FOREIGN KEY'
   and ccu.table_name = 'categories'
   and ccu.table_schema = 'public';


-- PASO 2 — UNIFICAR. Selecciona TODO el bloque, del begin al commit.
begin;

create temp table dup_merge on commit drop as
with norm as (
  select id, name,
         regexp_replace(
           translate(lower(btrim(name)),
                     'áàäâãéèëêíìïîóòöôõúùüûñç',
                     'aaaaaeeeeiiiiooooouuuunc'),
           '\s+', ' ', 'g') as clave
    from public.categories
),
conteo as (
  select n.id, n.name, n.clave,
         (select count(*) from public.products p where p.category_id = n.id)
           as productos
    from norm n
),
ranked as (
  select c.id, c.name, c.clave, c.productos,
         row_number() over (
           partition by c.clave order by c.productos desc, c.name
         ) as puesto
    from conteo c
)
select r.id as perdedora,
       (select r2.id from ranked r2
         where r2.clave = r.clave and r2.puesto = 1) as ganadora
  from ranked r
 where r.puesto > 1;

update public.products p
   set category_id = d.ganadora
  from dup_merge d
 where p.category_id = d.perdedora;

delete from public.categories c
 using dup_merge d
 where c.id = d.perdedora;

commit;


-- PASO 3 — COMPROBAR. Tiene que devolver cero filas.
select regexp_replace(
         translate(lower(btrim(name)),
                   'áàäâãéèëêíìïîóòöôõúùüûñç',
                   'aaaaaeeeeiiiiooooouuuunc'),
         '\s+', ' ', 'g') as clave,
       count(*)                as veces,
       string_agg(name, ' | ') as nombres
  from public.categories
 group by 1
having count(*) > 1;
