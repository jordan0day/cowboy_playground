defmodule CowboyPlayground do
  use Application

  def start(_type, _args) do
    dispatch = :cowboy_router.compile([{:_, [{:_, CowboyPlayground.Handler, []}]}])
    proto_opts = [ {:env, [ {:dispatch, dispatch} ]}, {:onrequest, &CowboyPlayground.Handler.on_request/1} ]

    IO.puts "dispatch: #{inspect dispatch}"

    :cowboy.start_http(:playground, 100, [{:port, 8080}], proto_opts)
  end
end
