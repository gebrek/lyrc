defmodule Lyrc do
end

defmodule AZlyrics do
  def base_url do
    "https://www.azlyrics.com/"
  end

  def search_artist(artist_name, artist_list) do
    Enum.map(artist_list,
      fn({name, link})->
	{String.jaro_distance(artist_name, name), {name, link}}
      end)
      |> Enum.sort_by(fn({n, _})-> n end, &>=/2)
  end

  def get(url) do
    headers = []
    options = []
    url
    |> HTTPoison.get(headers, options)
  end

  def az_directory(letter) do
    url = base_url()<>letter<>".html"
    get(url)
    |> handle_az_dir_response(url)
  end
  def handle_az_dir_response({:ok, %{body: body}}, url) do
    tags = body
    |> Floki.find("div.artist-col a")
    # |> Floki.attribute("href")
    Enum.zip(Floki.text(tags, sep: ";;") |> String.split(";;"), Floki.attribute(tags, "href"))
  end
  
  def get_lyric(url) do
    headers = []
    options = []
    url
    |> HTTPoison.get(headers, options)
    |> handle_lyric_response(url)
  end

  def handle_lyric_response({:ok, %{body: body}}, url) do
    {_,_,child_nodes} = body
    |> Floki.find("div.col-lg-8 div")
    |> Enum.at(4)    
    child_nodes
    |> filter_strings
    |> Enum.join()
    |> String.split("\r\n")
  end

  def filter_strings(list) do
    Enum.filter(list, &(is_bitstring(&1)))
  end

  def readit do
    File.read!("copycat.html")
    |> Floki.find("div.col-lg-8 div")
  end
end
