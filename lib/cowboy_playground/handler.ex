require Logger

defmodule CowboyPlayground.Handler do
  @servers [%{host: "localhost", port: 4010}, %{host: "localhost", port: 4011}]

  def on_request(req) do
    # TODO: Move request handling out of handle and into on_request,
    # which should slightly speed up routing time.
    Logger.debug inspect(req)
    req
  end

  def init({transport, proto_name}, req, opts) do
    start_time = :erlang.now()

    # Seed the RNG, since the httphandler is re-initted for each request, we 
    # need to re-seed on init -- otherwise :random.uniform will always return
    # the same result.
    :random.seed(:erlang.now())

    {:ok, req, start_time}
  end

  def handle(req, state) do

    {:ok, body, req} = :cowboy_req.body(req)
    Logger.debug inspect(body)
    # TODO: handle chunked request bodies larger than 8MB. By default, 8MB is
    # the most Cowboy will read from the request.
    # See http://ninenines.eu/docs/en/cowboy/1.0/manual/cowboy_req/#request_body_related_exports

    {cookies, req} = :cowboy_req.cookies(req)

    {headers, req} = :cowboy_req.headers(req)

    # {peer, req} = :cowboy_req.peer(req)

    {querystring, req} = :cowboy_req.qs(req)

    # {version, req} = :cowboy_req.version(req)

    {host, req} = :cowboy_req.host(req)

    {hostinfo, req} = :cowboy_req.host_info(req)

    {host_url, req} = :cowboy_req.host_url(req)

    {port, req} = :cowboy_req.port(req)

    {path, req} = :cowboy_req.path(req)

    {url, req} = :cowboy_req.url(req)

    {method, req} = :cowboy_req.method(req)

    Logger.debug "Processing #{method} request for #{url}"

    server = get_random_server()
 
    new_url = Regex.replace(~r/^#{host_url}/, url, "http://#{server.host}:#{server.port}")

    options = Application.get_env(:cowboy_playground, :httpoison_config, [])

    method = case method do
      "DELETE" -> :delete
      "GET" -> :get
      "HEAD" -> :head
      "OPTIONS" -> :options
      "PATCH" -> :patch
      "POST" -> :post
      "PUT" -> :put
      other -> 
        # TODO: Decide if we want to reject non-standard request methods, add
        # a whitelist, or something else. This current implementation is
        # unsafe, as an attacker could crash the router by sending many
        # requests with unique methods -- atoms are never garbage collected.
        # See here: http://elixir-lang.org/getting_started/mix_otp/3.html
        other |> String.downcase |> String.to_atom
    end

    try do
      {time, {result, response}} = :timer.tc(HTTPoison, :request, [method, new_url, body, headers])
      Logger.debug "Call to #{new_url} completed with #{inspect result} in #{div(time, 1000)}ms."

      {:ok, req} = :cowboy_req.reply(response.status_code, Map.to_list(response.headers), response.body, req)

      {:ok, req, {state, time}}
    rescue
      e ->
        Logger.error inspect(e)
        {:error, req, {state, 0}}
    end
  end

  def terminate(reason, req, state) do
    start_time = elem(state, 0)
    req_time = elem(state, 1)

    total_time = :timer.now_diff(:erlang.now(), start_time)

    Logger.info "Total request time (time in router): #{inspect(div(total_time, 1000))}ms (#{inspect(div(total_time - req_time, 1000))}ms)"
    :ok
  end

  defp get_random_server do
    index = :random.uniform(length(@servers)) - 1
    Enum.at(@servers, index)
  end
end