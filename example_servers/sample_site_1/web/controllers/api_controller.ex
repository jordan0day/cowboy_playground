require Logger

defmodule SampleSite.ApiController do
  use Phoenix.Controller

  plug :action

  def index(conn, _params) do
    text conn, "Hello from the server running at #{conn.host}:#{conn.port}"
  end

  def show(conn, params) do
    Logger.debug "In show. params: #{inspect params}"
    path_param = params["path_param"]
    text conn, "[#{conn.host}:#{conn.port}] - Your path was '#{path_param}'"
  end

  def handle_post(conn, params) do
    Logger.debug "In handle_post. conn: #{inspect conn}\nparams: #{inspect params}"
    text conn, "You POSTed with params #{inspect params}"
  end

  def handle_put(conn, params) do
    Logger.debug "in handle_put. conn: #{inspect conn}\nparams: #{inspect params}"
    text conn, "You PUTed with params #{inspect params}"
  end

  def handle_delete(conn, params) do
    Logger.debug "in handle_delete. conn: #{inspect conn}\nparams: #{inspect params}"
    text conn, "You DELETEed with params #{inspect params}"
  end

  def handle_options(conn, params) do
    Logger.debug "in handle_options. conn: #{inspect conn}\nparams: #{inspect params}"

    conn
    |> put_resp_header("allow", "[\"DELETE\", \"GET\", \"HEAD\", \"OPTIONS\", \"PATCH\", \"POST\", \"PUT\"]")
    |> text "You OPTIONed with params #{inspect params}"
  end

  def handle_patch(conn, params) do
    Logger.debug "in handle_patch. conn: #{inspect conn}\nparams: #{inspect params}"
    text conn, "You PATCHed with params #{inspect params}"    
  end
end