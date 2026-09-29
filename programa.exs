defmodule Programa do

  def main do

  end
end

defmodule Validacion do

  def validar(codigo, lote, dia, kilo, porcentaje_verde) do

    with  {:ok, codigo_validado} <- validar_codigo(codigo),
          {:ok, lote_validado} <- validar_lote(lote),
          {:ok, dia_validado} <- validar_dia(dia),
          {:ok, kilo_validado} <- validar_kilo(kilo),
          {:ok, porcentaje_verde_validado} <- validar_porcentaje_verde(porcentaje_verde) do

    {:ok, codigo_validado,lote_validado,dia_validado,kilo_validado,porcentaje_verde_validado}

    else
      {:error, motivo} -> "Error: #{motivo}"
    end
  end

  def validar_codigo(codigo) do

    Datos.recolectores()
    |>Enum.any?( fn recolector -> recolector.codigo == codigo end)
    |>if  do
      {:ok, codigo}
    else
      {:error, :recolector_desconocido}
    end
  end

  def validar_lote(loteid) do

    Datos.lotes()
    |>Enum.any?( fn lote -> lote.id == loteid end)
    |>if  do
      {:ok, loteid}
    else
      {:error, :lote_desconocido}
    end
  end

  def validar_dia(dia) when is_integer(dia) do # is_integer valida que el numero sea entero

    if dia in 1..6 do #aca indicamos el rango que debe de tener dia
      {:ok, dia}
    else
      {:error, :dia_invalido}
    end
  end
  def validar_dia(dia), do: {:error, :dia_invalido}

  def validar_kilo(kilo) when kilo > 0 and kilo <= 250, do: {:ok, kilo}
  def validar_kilo(kilo), do: {:error, :kilos_fuera_de_rango}

  def validar_porcentaje_verde(verde) when verde >=0 and verde <= 100, do: {:ok, verde}
  def validar_porcentaje_verde(verde), do: {:error, :porcentaje_invalido}

end

defmodule CalcularPago do

  @tarifa_base 1.000
  @kilos_diarios_bonificación  250
  @bonificación_diaria 8.000
  @descuento_alimentacion  12.000


  def liquidacion(codigo, lote, dia, kilo, porcentaje_verde) do

    
  end

  def pagar_pesaje(kilos, porcentaje_verde) do

    kilos*@tarifa_base
  end

  def bonificacion_productividad(kilos) when kilos>=@kilos_diarios_bonificación, do: @bonificación_diaria
  def bonificacion_productividad(_kilos), do: 0

  def descuento_alimentacion(), do: @descuento_alimentacion

  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde <= 2, do: 1.05

  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde > 2 and porcentaje_verde <= 5, do: 1

  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde > 5 and porcentaje_verde <= 10, do: 0.90

  def porcentaje_verdes(porcentaje_verde) when porcentaje_verde > 10, do: 0.70


end
