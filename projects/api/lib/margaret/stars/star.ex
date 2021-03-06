defmodule Margaret.Stars.Star do
  @moduledoc """
  The Star schema and changesets.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias __MODULE__

  alias Margaret.{
    Repo,
    Accounts.User,
    Stories.Story,
    Comments.Comment
  }

  @type t :: %Star{}

  schema "stars" do
    # The user that starred the starrable.
    belongs_to(:user, User)

    # Starrables.
    belongs_to(:story, Story)
    belongs_to(:comment, Comment)

    timestamps()
  end

  @doc """
  Builds a changeset for inserting a star.
  """
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) do
    permitted_attrs = ~w(
      user_id
      story_id
      comment_id
    )a

    required_attrs = ~w(
      user_id
    )a

    %Star{}
    |> cast(attrs, permitted_attrs)
    |> validate_required(required_attrs)
    |> assoc_constraint(:user)
    |> assoc_constraint(:story)
    |> assoc_constraint(:comment)
    |> unique_constraint(:user, name: :stars_user_id_story_id_index)
    |> unique_constraint(:user, name: :stars_user_id_comment_id_index)
    |> check_constraint(:user, name: :only_one_not_null_starrable)
  end

  @doc """
  Filters the stars by story.
  """
  @spec by_story(Ecto.Queryable.t(), Story.t()) :: Ecto.Query.t()
  def by_story(query \\ Star, %Story{id: story_id}),
    do: where(query, [..., s], s.story_id == ^story_id)

  @doc """
  Filters the stars by comment.
  """
  @spec by_comment(Ecto.Queryable.t(), Comment.t()) :: Ecto.Query.t()
  def by_comment(query \\ Star, %Comment{id: comment_id}),
    do: where(query, [..., s], s.comment_id == ^comment_id)

  @doc """
  Filters the stars by user.
  """
  @spec by_user(Ecto.Queryable.t(), User.t()) :: Ecto.Query.t()
  def by_user(query \\ Star, %User{id: user_id}),
    do: where(query, [..., s], s.user_id == ^user_id)

  @doc """
  Preloads the user of a star.
  """
  @spec preload_user(t()) :: t()
  def preload_user(%Star{} = star), do: Repo.preload(star, :user)

  @doc """
  Preloads the story of a star.
  """
  @spec preload_story(t()) :: t()
  def preload_story(%Star{} = star), do: Repo.preload(star, :story)

  @doc """
  Preloads the comment of a star.
  """
  @spec preload_story(t()) :: t()
  def preload_comment(%Star{} = star), do: Repo.preload(star, :comment)
end
