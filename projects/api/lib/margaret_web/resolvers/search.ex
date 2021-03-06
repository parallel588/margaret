defmodule MargaretWeb.Resolvers.Search do
  @moduledoc """
  The Search GraphQL resolvers.
  """

  # import MargaretWeb.Helpers, only: [ok: 1]
  alias MargaretWeb.Helpers

  @doc """
  Resolves the search.
  """
  def resolve_search(_, _, _) do
    Helpers.GraphQLErrors.not_implemented()
  end
end
