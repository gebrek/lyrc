defmodule Lyrc do
end

defmodule AZlyrics do
  def base_url do
    "https://www.azlyrics.com/"
  end

  
  def search_artist(artist_name) do
    letter = String.downcase(String.slice(artist_name, 0..0))
    search_artist(artist_name, az_directory(letter))
  end
  def search_artist(artist_name, artist_list) do
    Enum.map(artist_list,
      fn({name, link})->
	{String.jaro_distance(artist_name, name), {name, link}}
      end)
      |> Enum.sort_by(fn({n, _})-> n end, &>=/2)
    |> Enum.take(10)
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

  def get_albums(artist_url) do
    url = base_url()<>artist_url
    get(url)
    |> handle_album_response(url)
  end
  def handle_album_response({:ok, %{body: body}}, url) do
    tags = body
    |> Floki.find("div#listAlbum")
    [{_, _, child_nodes}|_] = tags
    child_nodes
    |> handle_songs_per_album()
  #   Enum.zip(
  #     Floki.text(tags, sep: ";;") |> String.split(";;"),
  #     Enum.map(Floki.attribute(tags, "href"), &String.replace_leading(&1, "../", "")))
  end
  def handle_songs_per_album([], cur_alb, acc) do
    [cur_alb|acc]
  end
  def handle_songs_per_album([{tag_name, tag_attr, tag_sub}|rest], cur_alb \\ {:name, []}, acc \\ []) do
    case tag_attr do
      [{"class", "album"}] ->
	handle_songs_per_album(rest, {Floki.text(tag_sub), []}, [cur_alb|acc])
      [{"href", link}|_] ->
	handle_songs_per_album(rest, {elem(cur_alb,0), 
				      [String.replace_leading(link, "../", "")|
				       elem(cur_alb,1)]},
	  acc)
      _ ->
	handle_songs_per_album(rest, cur_alb, acc)
    end
  end
end

defmodule AZlyrics.Artists do
  # TODO: encapsulate local state around queried artists, instead of pinging every time
  # STATE: [{artist_name, rel_url_link}]
end

