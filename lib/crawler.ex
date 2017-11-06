alias :mnesia, as: Mnesia

defmodule Crawler do
  @moduledoc """
  Memoized web pages. Simply get and forget.
"""

  def get_links(url) do
    url
    |> Crawler.get
    |> Floki.find("a")
    |> Floki.attribute("href")
  end

  def known?(url) do
    case Crawler.DB.read(url) do
      [] -> false
      [x|_] -> true
    end
  end

  def get(url) do
    url
    |> Crawler.DB.read
    |> try_db(url)
  end

  defp try_db([], url) do
    url
    |> HTTPoison.get([], [])
    |> try_web(url)
  end
  defp try_db([{Page, url, html, _date}|_], url) do
    html
  end

  defp try_web({:ok, resp}, _url) do
    resp
    |> Crawler.DB.write
    resp.body
  end
end

defmodule Crawler.DB do
  def create do
    Mnesia.create_table(Page, [attributes: [:url, :html, :date_recorded],
			       disc_copies: [node()]])
  end
  def recreate do
    Mnesia.delete_table(Page)
    create()
  end

  def write(%HTTPoison.Response{request_url: url, body: body, status_code: _n} = resp) do
    Mnesia.dirty_write({Page, url, body, DateTime.utc_now()})
    resp
  end

  def read(url) do
    Mnesia.dirty_read({Page, url})
  end

  def list do
    :mnesia.transaction(
      fn ->
	:mnesia.match_object({Page, :_, :_, :_})
      end)
  end
end
