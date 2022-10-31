defmodule LazyLoadExampleWeb.PageLive do
  use LazyLoadExampleWeb, :live_view
  use LazyLoadExampleWeb.AsyncHook

  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:posts, [])
      |> assign(:tags, [])
      |> assign_async(:posts, fn -> load_posts() end)
      |> assign_async(:tags, fn -> load_tags() end, &handle_tags/2)
    }
  end

  def render(assigns) do
    ~H"""
    <h2>Posts</h2>

    <%= if @loading?.posts do %>
      <div>Loading...</div>
    <% else %>
      <ul>
        <%= for post <- @posts do %>
          <li><%= post %></li>
        <% end %>
      </ul>
    <% end %>

    <hr />

    <h2>Tags</h2>

    <%= if @loading?.tags do %>
      <div>Loading...</div>
    <% else %>
      <ul>
        <%= for tag <- @tags do %>
          <li><%= tag %></li>
        <% end %>
      </ul>
    <% end %>
    """
  end

  def handle_tags({:error, reason}, socket) do
    put_flash(socket, :error, reason)
  end

  def handle_tags({:ok, tags}, socket) do
    assign(socket, :tags, tags)
  end

  def load_posts do
    :timer.sleep(3_000)
    ["a", "b", "c"]
  end

  def load_tags do
    :timer.sleep(4_000)
    {:error, "Could not fetch tags, API is down"}
  end
end
