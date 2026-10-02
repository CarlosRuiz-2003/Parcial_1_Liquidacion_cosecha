defmodule Programa do

  def main do
    lista_pesajes = Util.datos_pesajes
    lista_recolectores =  Util.datos_recolectores
    lista_lotes = Util.datos_lotes
    {pesajes_validados, _pesajes_rechazados} = Validacion.validar_todos_pesajes(lista_pesajes, lista_recolectores, lista_lotes)

    liquidaciones = Liquidacion.liquidar_todos_trabajadores(lista_recolectores, pesajes_validados)
    IO.inspect(liquidaciones)
  end
end


defmodule Validacion do

  def validar_todos_pesajes(pesajes, recolectores, lotes) do
    Enum.reduce(pesajes, {[],[]}, fn pesaje, {validos, rechazados}->
      case validar(pesaje, lotes, recolectores) do
        {:ok, pesaje_validado} ->
          {[pesaje_validado| validos], rechazados}
        {:error, motivo} ->
          {validos, [{pesaje, motivo} | rechazados]}
      end
    end)

  end

  def validar(pesaje, lotes, recolectores) do

    with  {:ok} <- validar_codigo(pesaje.recolector, recolectores),
          {:ok} <- validar_lote(pesaje.lote, lotes),
          {:ok} <- validar_dia(pesaje.dia),
          {:ok} <- validar_kilo(pesaje.kilos),
          {:ok} <- validar_porcentaje_verde(pesaje.verdes) do

    {:ok, pesaje}

    else
      {:error, motivo} -> {:error, motivo}
    end
  end

  def validar_codigo(codigo, recolectores) do
    Enum.any?(recolectores, fn recolector -> recolector.codigo == codigo end)
    |>if  do
      {:ok}
    else
      {:error, :recolector_desconocido}
    end
  end

  def validar_lote(loteid, lotes) do
    Enum.any?(lotes, fn lote -> lote.id == loteid end)
    |>if  do
      {:ok}
    else
      {:error, :lote_desconocido}
    end
  end

  def validar_dia(dia) when is_integer(dia) and dia in 1..6, do: {:ok} # is_integer valida que el numero sea entero
  def validar_dia(_), do: {:error, :dia_invalido}

  def validar_kilo(kilo) when kilo > 0 and kilo <= 250, do: {:ok}
  def validar_kilo(_), do: {:error, :kilos_fuera_de_rango}

  def validar_porcentaje_verde(verde) when verde >=0 and verde <= 100, do: {:ok}
  def validar_porcentaje_verde(_), do: {:error, :porcentaje_invalido}

end

defmodule Liquidacion do

  @tarifa_base 1.000
  @kilos_diarios_bonificacion  250
  @bonificación_diaria 8.000
  @descuento_alimentacion  12.000

  def liquidar_todos_trabajadores(recolectores, pesajes_validados) do
    Enum.map(recolectores, fn recolector ->
      pesajes = Enum.filter(pesajes_validados, fn pesaje -> IO.inspect(pesaje.recolector) == IO.inspect(recolector.codigo) end)
      liquidacion(recolector, pesajes)
    end)
  end

  def liquidacion(recolector, pesajes) do
    agrupado_dia = agrupar_dia(pesajes)

    detalles_dias =
      Enum.sort_by(agrupado_dia, fn {dia, _}-> dia end)
      |> Enum.map(fn {dia, pesajes_dia} ->
        kilos = Enum.sum(Enum.map(pesajes_dia, fn pesaje -> pesaje.kilos end))
        valor = Enum.sum(Enum.map(pesajes_dia, fn pesaje -> pagar_pesaje(pesaje) end))
        bonificacion = bonificacion_productividad(kilos)
        %{dia: dia, kilos: kilos, pesajes: valor, bonificacion: bonificacion}
      end)

    kilos = Enum.sum(Enum.map(pesajes, fn pesaje -> pesaje.kilos end))
    dinero_pesaje = Enum.sum(Enum.map(pesajes, fn pesaje -> pagar_pesaje(pesaje) end))
    bonificaciones = Enum.sum(Enum.map(detalles_dias, fn detalle -> detalle.bonificacion end))
    dias_trabajados = length(detalles_dias)
    descuento_alimentacion = descuento_alimentacion(recolector.alimentacion, dias_trabajados)
    total = dinero_pesaje + bonificaciones - descuento_alimentacion

    %{
      codigo: recolector.codigo,
      nombre: recolector.nombre,
      kilos: kilos,
      dinero_pesajes: dinero_pesaje,
      bonificaciones: bonificaciones,
      alimentacion: descuento_alimentacion,
      dias_trabajados: dias_trabajados,
      total: total,
      detalle_dias: detalles_dias
    }
  end

  def pagar_pesaje(pesaje) do
    pesaje.kilos * @tarifa_base * porcentaje_verdes(pesaje.verdes)
  end

  def bonificacion_productividad(kilos) when kilos>=@kilos_diarios_bonificacion, do: @bonificación_diaria
  def bonificacion_productividad(_), do: 0

  def descuento_alimentacion(true, dias), do: dias * @descuento_alimentacion
  def descuento_alimentacion(false, _dias), do: 0

  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde <= 2, do: 1.05
  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde > 2 and porcentaje_verde <= 5, do: 1
  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde > 5 and porcentaje_verde <= 10, do: 0.90
  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde > 10, do: 0.70

  def agrupar_dia(pasajes), do: Enum.group_by(pasajes, fn pesaje -> pesaje.dia end)
end
Programa.main()



  defmodule Reportes do

    #joined
    def generar_reportes do

    end


  end
