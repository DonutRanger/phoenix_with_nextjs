defmodule PhoenixWithNextjs.IntegrationCase do
  use ExUnit.CaseTemplate

  @moduledoc false

  using do
    quote do
      use Hound.Helpers

      import unquote(__MODULE__)
    end
  end

  setup_all do
    wait_for_node_server()
    :ok
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixWithNextjs.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PhoenixWithNextjs.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(PhoenixWithNextjs.Repo, self())
    Hound.start_session(
      metadata: metadata,
      additional_capabilities: %{
        chromeOptions: %{ "args" => [
          "--user-agent=#{Hound.Browser.user_agent(:chrome)}",
          "--headless",
          "--disable-gpu"
        ]}
      }
    )
    :ok
  end

  defp wait_for_node_server do
    node_server_uri = URI.parse(Application.fetch_env!(:phoenix_with_nextjs, :node_server))
    case :gen_tcp.connect(node_server_uri.host |> String.to_charlist(), node_server_uri.port, []) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true
      {:error, _} ->
        Process.sleep(500)
        wait_for_node_server()
    end
  end
end
