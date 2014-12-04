defmodule CowboyPlayground.DB.Models.Host do
  use Ecto.Model

  alias CowboyPlayground.DB.Models.Route

  schema "hosts" do
    has_many :routes,   Route
    field :hostname,    :string
    field :port,        :integer
    field :created_at,  :datetime
    field :updated_at,  :datetime
  end

  validate host,
    hostname: present(),
    port: present(),
    created_at: present(),
    updated_at: present()  
end