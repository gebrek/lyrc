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
  defp count([h|t], map) do
    count(t, Map.update(map, h, 1, &(&1+1)))
  end
  defp count([], map) do
    map
  end

  def frequency(words) do
    cnt = count(words)
    sum = Enum.reduce(cnt, 0, fn({_, v}, acc)->v+acc end)
    for {k, v} <- cnt do
      {k, v/sum}
    end
    |> Enum.sort_by(&(elem(&1,1)), &>=/2)
  end

  defp normalize(str) do
    Regex.replace(~r/[^\w\s]/, String.downcase(str), "")    
  end

end
