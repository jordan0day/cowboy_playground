defmodule SampleSite.PageController do
  use Phoenix.Controller

  plug :action

  def index(conn, _params) do
    text conn, "conn is #{inspect conn}"
    #render conn, "index.html"
  end
end
