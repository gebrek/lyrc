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
    (base_url()<>url)
    |> HTTPoison.get(headers, options)
  end

  def get_disco(artist_url) do
    albs = AZlyrics.get_albums(artist_url)
    for {t, l} <- albs do
      {t, Enum.map(l, &AZlyrics.get_lyric(&1))}
    end
  end

  def az_directory(letter) do
    url = letter<>".html"
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
    get(url)
    |> handle_lyric_response(url)
  end

  def handle_lyric_response({:ok, %{body: body}}, url) do
    title = body |> Floki.find("title")
    |> Floki.text |> String.split("-")
    |> Enum.slice(1..-1) |> Enum.join("-")
    |> String.trim_leading
    {_,_,child_nodes} = body
    |> Floki.find("div.col-lg-8 div")
    |> Enum.at(4)    
    lyrics = child_nodes
    |> filter_strings
    |> Enum.join()
    |> String.split("\n")
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(&(&1 == ""))
    {title, lyrics}
  end

  def filter_strings(list) do
    Enum.filter(list, &(is_bitstring(&1)))
  end

  defp read_album_title(str) do
    cond do
      not(is_bitstring(str)) ->
	""
      String.starts_with?(str, ["EP:", "album:"]) ->
	Enum.at(String.split(str, "\""), 1)
      String.starts_with?(str, "other songs:") ->
	"Other Songs"
      true ->
	""
    end
  end

  def get_albums(artist_url) do
    url = artist_url
    get(url)
    |> handle_album_response(url)
  end
  def handle_album_response({:ok, %{body: body}}, url) do
    tags = body
    |> Floki.find("div#listAlbum")
    [{_, _, child_nodes}|_] = tags
    albums = child_nodes
    |> handle_songs_per_album()
    for {title, songs} <- albums do
      {read_album_title(title), songs}
    end
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

defmodule LyricStore do
  # TODO: encapsulate local state around queried artists, instead of pinging every time
  # STATE: 
  # [{artistname, [{albumname, [{songname, lyrics}, ...]}, ...]}, ...]
  def open() do
    :dets.open_file(:store, [type: :set])
  end

  # def init() do
  #   :dets.new(:store, [:set, :protected, :named_table])
  # end

  def make_tree_records({root, branchs}) do
    for {albs, songs} <- branchs do
      for {title, lyrics} <- songs do
	{root, albs, title, lyrics}
      end
    end
    |> List.flatten
  end

  def add_artist_disco({artist_name, artist_disco}) do
    empty = fn({x, y}) ->
      case {x, y} do
	{"", _} ->
	  true
	{_, []} ->
	  true
	_ ->
	  false
      end
    end
    :dets.insert(:store, {artist_name, Enum.reject(artist_disco, empty)})
  end
end

defmodule Cache do
  def store(path, term) do
    File.write!(path, :erlang.term_to_binary(term))
  end
  def read(path) do
    File.read!(path) |> :erlang.binary_to_term
  end
end
