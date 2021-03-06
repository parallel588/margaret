defmodule MargaretWeb.Resolvers.Nodes do
  @moduledoc """
  The Node GraphQL resolvers.
  """

  import MargaretWeb.Helpers, only: [ok: 1]

  alias Margaret.{Accounts, Stories, Publications, Collections, Comments, Notifications, Tags}
  alias Accounts.User
  alias Stories.Story
  alias Publications.{Publication, PublicationInvitation}
  alias Collections.Collection
  alias Comments.Comment
  alias Notifications.Notification
  alias Tags.Tag

  @doc """
  Resolves the type of the resolved object.
  """
  def resolve_type(%User{}, _), do: :user
  def resolve_type(%Story{}, _), do: :story
  def resolve_type(%Publication{}, _), do: :publication
  def resolve_type(%PublicationInvitation{}, _), do: :publication_invitation
  def resolve_type(%Collection{}, _), do: :collection
  def resolve_type(%Comment{}, _), do: :comment
  def resolve_type(%Notification{}, _), do: :notification
  def resolve_type(%Tag{}, _), do: :tag
  def resolve_type(_, _), do: nil

  @doc """
  Resolves the node from its type and global ID.
  """
  def resolve_node(%{type: :user, id: user_id}, _) do
    user_id
    |> Accounts.get_user()
    |> ok()
  end

  def resolve_node(%{type: :story, id: story_id}, %{context: %{viewer: viewer}}) do
    resolve_story(story_id, viewer)
  end

  def resolve_node(%{type: :story, id: story_id}, _), do: resolve_story(story_id, nil)

  def resolve_node(%{type: :publication, id: publication_id}, _) do
    publication_id
    |> Publications.get_publication()
    |> ok()
  end

  def resolve_node(%{type: :publication_invitation, id: invitation_id}, _) do
    invitation_id
    |> Publications.get_invitation()
    |> ok()
  end

  def resolve_node(%{type: :collection, id: collection_id}, _) do
    collection_id
    |> Collections.get_collection()
    |> ok()
  end

  def resolve_node(%{type: :comment, id: comment_id}, %{context: %{viewer: viewer}}) do
    resolve_comment(comment_id, viewer)
  end

  def resolve_node(%{type: :tag, id: tag_id}, _) do
    tag_id
    |> Tags.get_tag()
    |> ok()
  end

  defp resolve_story(story_id, viewer) do
    story_id
    |> Stories.get_story()
    |> do_resolve_story(viewer)
  end

  defp do_resolve_story(%Story{} = story, viewer) do
    if Stories.can_see_story?(story, viewer), do: {:ok, story}, else: {:ok, nil}
  end

  defp do_resolve_story(nil, _), do: {:ok, nil}

  defp resolve_comment(comment_id, viewer) do
    comment_id
    |> Comments.get_comment()
    |> do_resolve_comment(viewer)
  end

  defp do_resolve_comment(%Comment{} = comment, viewer) do
    if Comments.can_see_comment?(comment, viewer), do: {:ok, comment}, else: {:ok, nil}
  end

  defp do_resolve_comment(nil, _), do: {:ok, nil}
end
