-- ============================================================================
--  Ajuste de stock seguro con varios usuarios a la vez.
--
--  Ejecutar en Supabase → SQL Editor. Seguro de correr varias veces.
--  No modifica datos: solo agrega una función.
--
--  EL PROBLEMA QUE RESUELVE
--  La app venía leyendo el stock, calculando el nuevo valor en el celular y
--  escribiéndolo de vuelta. Con dos personas moviendo el MISMO producto casi
--  al mismo tiempo, las dos leen el mismo número de partida y la segunda
--  escritura pisa a la primera:
--
--      Hay 100 unidades.
--      Marisol saca 10  -> lee 100, escribe 90
--      La jefa saca 5   -> lee 100 (antes de que se guarde lo anterior),
--                          escribe 95
--      Queda 95 cuando debería quedar 85. La salida de 10 se perdió del
--      stock, aunque el movimiento sí quedó registrado.
--
--  Aquí la suma la hace Postgres dentro de una sola instrucción. La fila
--  queda bloqueada mientras se actualiza, así que la segunda operación parte
--  del valor ya actualizado y no se pierde ninguna.
-- ============================================================================

create or replace function public.ajustar_stock(
  p_product_id uuid,
  p_delta      integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nuevo_stock integer;
begin
  -- "stock + p_delta" lo resuelve la base leyendo el valor vigente en ese
  -- instante, no uno que el celular leyó antes.
  update public.products
     set stock = greatest(stock + p_delta, 0)
   where id = p_product_id
  returning stock into v_nuevo_stock;

  if not found then
    raise exception 'No existe el producto %', p_product_id;
  end if;

  return v_nuevo_stock;
end;
$$;

comment on function public.ajustar_stock(uuid, integer) is
  'Suma o resta stock de forma atómica. p_delta positivo para entradas y '
  'negativo para salidas. Evita que dos usuarios simultáneos se pisen.';

grant execute on function public.ajustar_stock(uuid, integer) to anon, authenticated;

-- ============================================================================
-- Verificación: suma 0 a un producto y devuelve su stock sin alterarlo.
-- ============================================================================
select p.name,
       p.stock as stock_antes,
       public.ajustar_stock(p.id, 0) as stock_despues
from public.products p
order by p.name
limit 1;
