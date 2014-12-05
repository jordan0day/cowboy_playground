require Logger

defmodule CowboyPlayground.Handler do

  def on_request(req) do
    # TODO: Move request handling out of handle and into on_request,
    # which should slightly speed up routing time.
    Logger.debug inspect(req)
    req
  end

  def init({_transport, _proto_name}, req, opts) do
    start_time = :erlang.now()

    {:ok, req, start_time}
  end

  def handle(req, state) do

    {:ok, body, req} = :cowboy_req.body(req)
    
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

    if port == nil do
      port = 80
    end

    {path, req} = :cowboy_req.path(req)

    {url, req} = :cowboy_req.url(req)

    {method, req} = :cowboy_req.method(req)

    Logger.debug "Processing #{method} request for #{url}"

    # TODO: Handle when we don't have a route matching what's requested
    # Going with returning 503 here, that seems to be AWS's behavior for an ELB
    # that doesn't have any associated instances.
    case get_random_server(host, port) do
      nil ->
        {:ok, req} = :cowboy_req.reply(503, req)
        {:ok, req, {state, 0}}

      {server_host, server_port} ->
        new_url = Regex.replace(~r/^#{host_url}/, url, "http://#{server_host}:#{server_port}")

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
  end

  def terminate(_reason, _req, state) do
    start_time = elem(state, 0)
    req_time = elem(state, 1)

    total_time = :timer.now_diff(:erlang.now(), start_time)

    Logger.info "Total request time (time in router): #{inspect(div(total_time, 1000))}ms (#{inspect(div(total_time - req_time, 1000))}ms)"
    :ok
  end

  defp get_random_server(host, port) do
    routes = ConCache.get(:routes, "#{host}:#{port}")
    Logger.debug "Routes matching #{host}: #{inspect routes}"

    case routes do
      nil -> nil
      [route | []] -> route
      routes ->
        index = :random.uniform(length(routes)) - 1
        Enum.at(routes, index)
    end

    index = :random.uniform(length(routes)) - 1
    Enum.at(routes, index)
  end
end