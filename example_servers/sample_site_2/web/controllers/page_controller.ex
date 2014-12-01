defmodule SampleSite_2.PageController do
  use Phoenix.Controller

  plug :action

  def index(conn, _params) do
    text conn, "Hello from the server running at #{inspect conn.host} port #{inspect conn.port}\n"
  end
end
