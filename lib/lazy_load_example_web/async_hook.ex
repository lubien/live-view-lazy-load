defmodule LazyLoadExampleWeb.AsyncHook do
  @moduledoc """
  Adds async assign hook to LiveViews

  ## Usage

  In a LiveView:

      defmodule MyLive do
        use LazyLoadExampleWeb.AsyncHook

        def mount(_, _, socket) do
          {:ok, assign_async(socket, :posts, fn -> expensive_op(123) end)}
        end
      end

  You can also hook into the results to handle special error conditions
  or forward updates to a LiveComponent:

      defmodule MyLive do
        use LazyLoadExampleWeb.AsyncHook

        def mount(_, _, socket) do
          {:ok, assign_async(socket, :posts, fn -> expensive_op(123) end), &handle_posts/2}
        end

        defp handle_posts({:ok, posts}, socket) do
          assign(socket, :posts, posts)
        end
        defp handle_posts({:error, reason}, socket) do
          put_flash(reason, :error, reason)
        end
      end
  """

  import Phoenix.LiveView, only: [attach_hook: 4, assign: 3]

  defmacro __using__(_params) do
    quote do
      import LazyLoadExampleWeb.AsyncHook, only: [assign_async: 3, assign_async: 4], warn: false
      on_mount LazyLoadExampleWeb.AsyncHook
    end
  end

  def on_mount(:default, _params, _session, socket) do
    socket =
      attach_hook(socket, :assign_async, :handle_info, fn
        {:assign_async, key, value, nil}, socket ->
          {:halt,
            socket
            |> assign_loading(key, false)
            |> assign(key, value)
          }

        {:assign_async, key, value, on_done}, socket ->
          {:halt,
            value
            |> on_done.(socket)
            |> assign_loading(key, false)
          }

        _event, socket ->
          {:cont, socket}
      end)

    {:cont, socket}
  end

  def assign_async(socket, key, func) when is_function(func, 0) do
    assign_async(socket, key, func, nil)
  end

  def assign_async(socket, key, func, on_done) when is_function(func, 0) do
    pid = self()
    Task.Supervisor.async(LazyLoadExampleWeb.TaskSupervisor, fn ->
      send(pid, {:assign_async, key, func.(), on_done})
    end)

    assign_loading(socket, key, true)
  end

  defp assign_loading(socket, key, value) do
    assign(socket, :loading?, Map.put(socket.assigns[:loading?] || %{}, key, value))
  end
end
