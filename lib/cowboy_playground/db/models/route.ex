defmodule CowboyPlayground.DB.Models.Route do
  use Ecto.Model

  alias CowboyPlayground.DB.Models.Host

  schema "routes" do
    belongs_to :host,          Host
    field :hostname,           :string
    field :port,               :integer
    field :created_at,         :datetime
    field :updated_at,         :datetime
    field :secure_connection,  :boolean
  end

  validate host,
    host_id: present(),
    hostname: present(),
    port: present(),
    created_at: present(),
    updated_at: present()
end