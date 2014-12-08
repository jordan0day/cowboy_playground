require Logger

defmodule CowboyPlayground.RouteServer do
  import Ecto.Query

  alias CowboyPlayground.DB.Models.Host
  alias CowboyPlayground.DB.Models.Route
  alias CowboyPlayground.Repo

  @spec start_link() :: {:ok, pid} | {:error, String.t}
  def start_link do
    Logger.debug "Starting the RouteServer process #{inspect self}"

    # This agent keeps track of the last time we fetched our routes (if ever).
    # Tuple: {started_at, last_fetch}
    Agent.start_link(fn -> {Ecto.DateTime.utc, nil} end, name: __MODULE__)

    # Try to load all the routes at startup.
    spawn(__MODULE__, :load_all_routes, [])

    updater_pid = spawn_link(__MODULE__, :update_routes, [])

    {:ok, updater_pid}
  end

  def load_all_routes() do
    Logger.debug "Performing initial route load."
    now = Ecto.DateTime.utc
    try do
      routes = Repo.all(from host in Host,
                        join: route in Route, on: route.host_id == host.id,
                        select: {host.hostname, host.port, route.hostname, route.port})

      get_route_hashdict(routes)
      |> Enum.each(fn({k, v}) ->
        # We can dirty put on initial load, because there won't be any routes
        # with matching keys...
        ConCache.dirty_put(:routes, k, v)
      end)

      Agent.update(__MODULE__, fn state ->
        {elem(state, 0), now}
      end)
      Logger.debug "Routes loaded at #{inspect now}"
    rescue
      e ->
        Logger.error "Error performing initial route load: #{inspect e}"
    end
    :ok
  end

  def update_routes() do
    receive do
    # TODO: Make this value configurable...
    after 60000 ->
      Logger.debug "updating routes..."
      now = Ecto.DateTime.utc

      case Agent.get(__MODULE__, fn state -> state end) do
        {_started, nil} ->
          # The initial load of routes failed for some reason. Try it now.
          Logger.debug "Cannot update routes -- initial route list has not yet been loaded."
          load_all_routes()

        {_started, last_fetch} ->
          try do
            routes = Repo.all(from host in Host,
                              join: route in Route, on: route.host_id == host.id,
                              where: host.updated_at > ^last_fetch,
                              select: {host.hostname, host.port, route.hostname, route.port})

            if (length(routes) == 0) do
            else
              Logger.debug "updated (or new) routes: #{inspect routes}"

              # Overwrite the old routes
              get_route_hashdict(routes)
              |> Enum.each(fn({k, v}) ->
                ConCache.put(:routes, k, v)        
              end)
            end

            Agent.update(__MODULE__, fn state ->
              {elem(state, 0), now}
            end)

            Logger.debug "Routes updated at #{inspect now}"
          rescue
            e -> 
              Logger.error "Error updating routes: #{inspect e}"
          end

        other ->
          Logger.error "Unexpected result retrieving RouteServer agent state: #{inspect other}"
      end
    end

    # Tail-call back into this function, setting up our update loop.
    update_routes()
  end

  defp get_route_hashdict(routes) do
    Enum.reduce(routes, HashDict.new(), fn(tup, dict) ->
      # Tuple: {host hostname, host port, route hostname, route port}
      host = "#{elem(tup, 0)}:#{elem(tup, 1)}"

      HashDict.merge(
        dict,
        HashDict.put(HashDict.new(), host, [{elem(tup, 2), elem(tup, 3)}]),
        fn (key, v1, v2) ->
          v1 ++ v2
        end)
    end)  
  end
end