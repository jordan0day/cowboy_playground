defmodule CowboyPlayground do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    :random.seed(:erlang.now())

    dispatch = :cowboy_router.compile([{:_, [{:_, CowboyPlayground.Handler, []}]}])
    proto_opts = [ {:env, [ {:dispatch, dispatch} ]}, {:onrequest, &CowboyPlayground.Handler.on_request/1} ]

    # TODO: Move the # of acceptors and port into env vars. Currently
    # hardcoded to 100 and 8080.
    {:ok, cowboy_pid} = :cowboy.start_http(:playground, 100, [{:port, 8080}], proto_opts)

    children = [
      worker(CowboyPlayground.Repo, []),
      
      # Start up ConCache, see ttl to zero so items won't expire.
      worker(ConCache, [[ttl: 0], [name: :routes]]),

      # The RouteLoader is the process that handles keeping the :routes cache
      # up-to-date.
      worker(CowboyPlayground.RouteServer, [])
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: CloudosBuildServer.Supervisor])
  end
end
