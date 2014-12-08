defmodule CowboyPlayground do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    :random.seed(:erlang.now())

    # TODO: Move the cowboy startup to occur *after* we've started up con_cache
    # and read in the route database. We don't want to start handling requests
    # until we're actually ready to handle them, after all...
    dispatch = :cowboy_router.compile([{:_, [{:_, CowboyPlayground.Handler, []}]}])
    proto_opts = [ {:env, [ {:dispatch, dispatch} ]}, {:onrequest, &CowboyPlayground.Handler.on_request/1} ]

    IO.puts "dispatch: #{inspect dispatch}"

    {:ok, cowboy_pid} = :cowboy.start_http(:playground, 100, [{:port, 8080}], proto_opts)
    IO.puts "cowboy_pid: #{inspect cowboy_pid}"

    children = [
      worker(CowboyPlayground.Repo, []),
      
      # Start up ConCache, see ttl to zero so items won't expire.
      worker(ConCache, [[ttl: 0], [name: :routes]]),

      # The RouteLoader is the process that handles keeping the :routes cache
      # up-to-date.
      worker(CowboyPlayground.RouteServer, [])
    ]

    {:ok, pid} = Supervisor.start_link(children, [strategy: :one_for_one, name: CloudosBuildServer.Supervisor])
    IO.puts "supervisor pid: #{inspect pid}"

    # TODO: Read the routes in from some kind of database. Eventually have a
    # child process that refreshes the route list every 300 seconds or so...
    #ConCache.put(:routes, "localhost", [{"localhost", 4010}, {"localhost", 4011}])

    {:ok, pid}
  end
end
