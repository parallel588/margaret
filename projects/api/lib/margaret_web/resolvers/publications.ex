defmodule MargaretWeb.Resolvers.Publications do
  @moduledoc """
  The Publication GraphQL resolvers.
  """

  import Ecto.Query
  alias Absinthe.Relay

  alias MargaretWeb.Helpers
  alias Margaret.{Repo, Accounts, Stories, Publications}
  alias Accounts.User
  alias Stories.Story
  alias Publications.{Publication, PublicationMembership, PublicationInvitation}

  def resolve_publication(%{name: name}, _) do
    {:ok, Publications.get_publication_by_name(name)}
  end

  def resolve_owner(%Publication{id: publication_id}, _, _) do
    {:ok, Publications.get_publication_owner(publication_id)}
  end

  def resolve_member(%Publication{id: publication_id}, %{member_id: %{id: member_id}}, _) do
    {
      :ok,
      Publications.get_publication_membership_by_publication_and_member(
        publication_id, member_id)
    }
  end

  def resolve_members(%Publication{id: publication_id}, args, _) do
    query = from u in User,
      join: pm in PublicationMembership, on: pm.member_id == u.id,
      where: pm.publication_id == ^publication_id

    Relay.Connection.from_query(query, &Repo.all/1, args)
  end

  def resolve_member_role(_, _, _) do
    {:ok, "Not implemented yet"}
  end

  def resolve_stories(%Publication{id: publication_id}, args, _) do
    query = from s in Story, where: s.publication_id == ^publication_id

    Relay.Connection.from_query(query, &Repo.all/1, args)
  end

  def resolve_followers(%Publication{id: publication_id}, args, _) do
    query = from u in User,
      join: f in Follow, on: f.follower_id == u.id,
      where: f.publication_id == ^publication_id

    Relay.Connection.from_query(query, &Repo.all/1, args)
  end

  def resolve_membership_invitations(
    %Publication{id: publication_id}, args, %{context: %{viewer: %{id: viewer_id}}}
  ) do
    publication_id
    |> Publications.can_see_invitations?(viewer_id)
    |> do_resolve_membership_invitations(publication_id, args)
  end

  def resolve_membership_invitations(_, _, _), do: {:ok, nil}

  defp do_resolve_membership_invitations(true, publication_id, args) do
    query = from pi in PublicationInvitation,
      where: pi.publication_id == ^publication_id

    Relay.Connection.from_query(query, &Repo.all/1, args)
  end

  defp do_resolve_membership_invitations(false, _, _), do: {:ok, nil}

  @doc """
  Resolves if the user is a member of the publication.
  """
  def resolve_viewer_is_a_member(%{id: publication_id}, _, %{context: %{viewer: viewer}}) do
    {:ok, Publications.is_publication_member?(publication_id, viewer.id)}
  end

  def resolve_viewer_is_a_member(_, _, _), do: {:ok, false}

  @doc """
  Resolves if the user can administer the publication.
  """
  def resolve_viewer_can_administer(%{id: publication_id}, _, %{context: %{viewer: viewer}}) do
    {:ok, Publications.is_publication_admin?(publication_id, viewer.id)}
  end

  def resolve_viewer_can_administer(_, _, _), do: {:ok, false}

  def resolve_viewer_can_follow(_, _, %{context: %{viewer: _viewer}}), do: {:ok, true}
  def resolve_viewer_can_follow(_, _, _), do: {:ok, false}

  def resolve_viewer_has_followed(
    %Publication{id: publication_id}, _, %{context: %{viewer: %{id: viewer_id}}}
  ) do
    {:ok, Accounts.get_follow(follower_id: viewer_id, publication_id: publication_id)}
  end

  def resolve_viewer_has_followed(_, _, _), do: {:ok, false}

  def resolve_create_publication(args, %{context: %{viewer: %{id: viewer_id}}}) do
    args
    |> Map.put(:owner_id, viewer_id)
    |> Publications.insert_publication()
    |> case do
      {:ok, %{publication: publication}} -> {:ok, %{publication: publication}}
      {:error, _} -> {:error, "s"}
    end
  end

  def resolve_create_publication(_, _), do: Helpers.GraphQLErrors.unauthorized()

  def resolve_update_publication(
    %{publication_id: _publication_id}, %{context: %{viewer: %{id: _viewer_id}}}
  ) do
    Helpers.GraphQLErrors.not_implemented()
  end

  def resolve_update_publication(_, _), do: Helpers.GraphQLErrors.unauthorized()
  
  @doc """
  Resolves the kick of a publication member.
  """
  def resolve_kick_member(%{member_id: member_id} = args, resolution) when is_binary(member_id) do
    args
    |> Map.update(:member_id, nil, &String.to_integer(&1))
    |> resolve_kick_member(resolution)
  end

  def resolve_kick_member(
    %{member_id: member_id}, %{context: %{viewer: %{id: viewer_id}}}
  ) when member_id === viewer_id do
    {:error, "You can't kick yourself."}
  end

  def resolve_kick_member(
    %{member_id: member_id, publication_id: publication_id}, 
    %{context: %{viewer: %{id: viewer_id}}}
  ) do
    publication_id
    |> Publications.is_publication_admin?(viewer_id)
    |> do_resolve_kick_member(publication_id, member_id)
  end

  def resolve_kick_member(_, _), do: Helpers.GraphQLErrors.unauthorized()

  defp do_resolve_kick_member(true, publication_id, member_id) do
    case Publications.kick_publication_member(publication_id, member_id) do
      {:ok, _} -> {:ok, %{publication: Publications.get_publication(publication_id)}}
      {:error, reason} -> {:error, reason}
    end
  end 

  defp do_resolve_kick_member(_, _, _), do: Helpers.GraphQLErrors.unauthorized() 

  def resolve_delete_publication(_, _) do
    Helpers.GraphQLErrors.not_implemented()
  end

  @doc """
  Resolves the leave of the viewer from the publication.
  """
  def resolve_leave_publication(
    %{publication_id: _publication_id},
    %{context: %{viewer: %{id: _viewer}}}
  ) do
    Helpers.GraphQLErrors.not_implemented()
  end

  def resolve_leave_publication(_, _), do: Helpers.GraphQLErrors.unauthorized()
end
