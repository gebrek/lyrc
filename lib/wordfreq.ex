defmodule WordFreq do
  def count(words) when is_list(words) do
    words
    |> Enum.join(" ")
    |> count
  end
  def count(words) when is_bitstring(words) do
    words
    |> normalize
    |> String.split(" ")
    |> count(%{})
  end
  defp count([], map) do
    map
  end
  defp count([h|t], map) do
    count(t, Map.update(map, h, 1, &(&1+1)))
  end

  def normalize(str) do
    Regex.replace(~r/[^\w\s]/, String.downcase(str), "")    
  end

end
