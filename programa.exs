defmodule Programa do

  def main do
    lista_pesajes = Util.datos_pesajes
    lista_recolectores =  Util.datos_recolectores
    lista_lotes = Util.datos_lotes
    {pesajes_validados, pesajes_rechazados} = Validacion.validar_todos_pesajes(lista_pesajes, lista_recolectores, lista_lotes)

    liquidaciones = Liquidacion.liquidar_todos_trabajadores(lista_recolectores, pesajes_validados)
    reporte = Reportes.rechazados_r1(pesajes_rechazados)
    reporte2 = Reportes.kilos_lote_r2(lista_lotes, pesajes_validados)
    reporte3 = Reportes.kilos_dia_r3(pesajes_validados)
    reporte4 = Reportes.liquidacion_semana_r4(liquidaciones)
    reporte5 = Reportes.rankin_recoleccion_r5(lista_recolectores, pesajes_validados)
    reporte6 = Reportes.mejor_calidad_r6(lista_recolectores, pesajes_validados)

    IO.puts(reporte)
    IO.puts(reporte2)
    IO.puts(reporte3)
    IO.puts(reporte4)
    IO.puts(reporte5)
    IO.puts(reporte6)
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
      pesajes = Enum.filter(pesajes_validados, fn pesaje -> pesaje.recolector == recolector.codigo end)
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
      dinero_pesaje: dinero_pesaje,
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

defmodule Reportes do

  def generar_reportes do

  end

  def rechazados_r1(rechazados) do

    detalles =
      case rechazados do
        [] -> "Sin pesajes Rechazados. \n"
        lista ->
          Enum.map_join(lista, "", fn {pesaje, motivo}->
            "#{pesaje.recolector} | #{pesaje.lote} | #{pesaje.dia} | #{pesaje.kilos} Kg | #{pesaje.verdes} % -> #{motivo} \n"

          end)

      end

    contar_motivos = Enum.frequencies_by(rechazados, fn {_pesajes, motivo} -> motivo end)
    #es una función del módulo Enum que recorre una coleccion, aplica una función a cada elemento y retorna un **mapa con la cantidad de motivos**
    #ejemplo dia_invalido: numero de dias invalidos

    map_contado = Enum.map_join(contar_motivos, "\n",fn {motivo, cantidad} -> "#{motivo}: #{cantidad}"end)

    "R1. Pesajes Rechazados \n" <>
    detalles <>
    "Rechazados por motivo \n" <>
    map_contado
  end

  def kilos_lote_r2(lotes, pesajes_validos) do

    lote =
      Enum.map(lotes, fn lote ->
      kilos =
        Enum.filter(pesajes_validos, fn pesaje -> pesaje.lote == lote.id end)
        |>Enum.map(fn pesaje -> pesaje.kilos end)
        |>Enum.sum()

        rendimiento = kilos / lote.hectareas
        {lote, kilos, rendimiento}
      end)

      ordenar_mapa =
        Enum.map_join(lote, "", fn {lote, kilos, rendimiento} ->
          "#{lote.nombre} | #{kilos} Kg | #{lote.hectareas} ha | #{rendimiento} kg/ha\n"
        end)

    "R2. Kilos por lote \n" <> ordenar_mapa
  end

  def kilos_dia_r3(pesajes_validos) do
    kilos_dia =
      Enum.map(1..6, fn dia ->
        kilos =
          Enum.filter(pesajes_validos, fn pesajes -> pesajes.dia == dia end)
          |>Enum.map(fn pesaje -> pesaje.kilos end)
          |>Enum.sum()

        {dia, kilos}

      end)

    ordenar_mapa =
      Enum.map_join(kilos_dia, "", fn {dia, kilos} ->
        estado =
          if kilos >= 400 do
            "Cumplio la meta"
          else
            "No cumplio la meta"
          end
          "Dia #{dia}: #{kilos} Kg -> #{estado} \n"
    end)

    todos = Enum.all?(kilos_dia, fn {_dia, kilos} -> kilos >= 400 end)
    alguno = Enum.any?(kilos_dia, fn {_dia, kilos} -> kilos >= 400 end)

    "R3. Kilos por día (meta: 400 kg) \n" <>
    ordenar_mapa <>
    "¿Se cumplió la meta todos los días?  #{if todos do "Si" else "No" end} \n" <>
    "¿Se cumplió la meta al menos un día? #{if alguno do "Si" else "No" end} \n"
  end

  def liquidacion_semana_r4(liquidaciones) do

    liquidacione =
      Enum.sort_by(liquidaciones, fn liquidacion -> liquidacion.total end, :desc)
      |> Enum.with_index(1)
      |>Enum.map_join("", fn {liquidacion, indice} ->
      "#{indice}. | #{liquidacion.nombre} | #{liquidacion.kilos} kg | " <>
      "#{liquidacion.dinero_pesaje} | #{liquidacion.bonificaciones} | " <>
      "#{liquidacion.alimentacion} | #{liquidacion.total}\n"

      end)

    "R4. Liquidación de la semana\n" <>
    "#  | Recolector  | Kilos | Pesajes | Bonificaciones | Alimentación | Neto\n" <>
    liquidacione

  end

  def rankin_recoleccion_r5(recolectores, pesajes_validos) do
    datos =
    Enum.map(1..6, fn dia ->
      por_recolector =
        Enum.map(recolectores, fn recolector ->
          kilos =
            Enum.filter(pesajes_validos,fn pesaje -> pesaje.dia == dia and pesaje.recolector == recolector.codigo end)
            |> Enum.map(fn pesaje -> pesaje.kilos end)
            |> Enum.sum()

          {recolector, kilos}
        end)
        |> Enum.filter(fn {_recolector, kilos} -> kilos > 0 end)

      {dia, por_recolector}
    end)

    ordenar_mapa =
      Enum.map_join(datos, "", fn
      {dia, []} -> "Día #{dia}: sin pesajes\n"
      {dia, candidatos} ->
        max_kilos = Enum.max_by(candidatos, fn {_recolector, kilos} -> kilos end) |> elem(1)
        nombres =
          candidatos
          |> Enum.filter(fn {_recolector, kilos} -> kilos == max_kilos end)
          |> Enum.map(fn {recolector, _kilos} -> recolector.nombre end)
          |> Enum.join(", ")

        "Día #{dia}: #{nombres} (#{max_kilos} kg)\n"
    end)

     mejores_por_persona =
      datos
      |> Enum.flat_map(fn {_dia, candidatos} ->
        case candidatos do
          [] -> []
          _ ->
            max_kilos = Enum.max_by(candidatos, fn {_recolector, kilos} -> kilos end) |> elem(1)
            candidatos
            |> Enum.filter(fn {_recolector, kilos} -> kilos == max_kilos end)
            |> Enum.map(fn {recolector, _kilos} -> recolector.codigo end)
        end
      end)
      |> Enum.frequencies()

    resumen =
      case mejores_por_persona do
        %{} ->
          ordenar_mapa <> "Más días como mejor recolector: ninguno\n"

        _ ->
          max_dias = mejores_por_persona |> Map.values() |> Enum.max()

          ganadores =
            recolectores
            |> Enum.filter(fn recolector -> Map.get(mejores_por_persona, recolector.codigo, 0) == max_dias end)
            |> Enum.map(& &1.nombre)
            |> Enum.join(", ")

          ordenar_mapa <> "Más días como mejor recolector: #{ganadores} (#{max_dias} días)\n"
      end

    "R5. Mejor recolector de cada día\n" <> resumen
  end

  def mejor_calidad_r6(recolectores, pesajes_validos) do
    candidatos =
      recolectores
      |> Enum.map(fn recolector ->
        propios = Enum.filter(pesajes_validos, &(&1.recolector == recolector.codigo))

        if length(propios) >= 3 do
          kilos = Enum.sum(Enum.map(propios, & &1.kilos))
          ponderado = Enum.sum(Enum.map(propios, fn pesaje -> pesaje.verdes * pesaje.kilos end)) / kilos
          {recolector, ponderado}
        end
      end)
      |> Enum.reject(&is_nil/1)

    case candidatos do
      [] ->
        "R6. Mejor calidad (mínimo 3 pesajes válidos)\nNo hay recolectores con al menos 3 pesajes válidos.\n"

      _ ->
        minimo = Enum.min_by(candidatos, fn {_recolector, porcentaje} -> porcentaje end) |> elem(1)

        nombres =
          candidatos
          |> Enum.filter(fn {_recolector, porcentaje} -> abs(porcentaje - minimo) < 1.0e-12 end)
          |> Enum.map(fn {recolector, _porcentaje} -> recolector.nombre end)
          |> Enum.join(", ")

        "R6. Mejor calidad (mínimo 3 pesajes válidos)\n" <>
          "#{nombres}, con #{minimo} % de verdes ponderado por kilos\n"
    end
  end

end
Programa.main()
