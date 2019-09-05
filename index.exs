defmodule TaxsToFile do
  def file({:error, reason}) do
    IO.puts "error opening the file, reason is #{reason}"
    reason
  end
  def file({:ok, data}) do
    data
      |> IO.stream(:line)
      |> Stream.drop(1)
      |> Stream.map(&(String.split(&1, ",")))
      |> Enum.to_list
      |> convertList
  end

  def convertList(list) when is_list(list) do
    for [id, <<_, place::binary>>, amount] <- list,
      do:
        [
          id: String.to_integer(id),
          ship_to: String.to_atom(place),
          amount: amount |> String.trim_trailing |> String.to_float
        ]
  end

  def applyTaxes(orders, taxes) when is_list orders do
    for [_, {_, ship_to}, {_, net}] = order <- orders, {place, tax} <- taxes do
      if ship_to == place do
        Keyword.put(order, :total_amount, (net + tax))
      else
        order
      end
    end
  end

  def applyTaxes(orders, _) when is_atom(orders), do: {:error, "Error procesing the orders"}
end

taxes = [NC: 0.075, TX: 0.08]


File.open("sales_taxes.csv")
  |> TaxsToFile.file
  |> TaxsToFile.applyTaxes(taxes)
  |> IO.inspect