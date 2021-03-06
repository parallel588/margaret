defmodule Margaret.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query
  alias Ecto.Multi

  alias Margaret.{
    Repo,
    Accounts,
    Publications,
    Stories,
    Follows
  }

  alias Accounts.{User, SocialLogin}
  alias Stories.Story
  alias Publications.PublicationMembership

  @typedoc """
  The tuple of `provider` and `uid` from an OAuth2 provider.
  """
  @type social_credentials :: {provider :: String.t(), uid :: String.t()}

  @doc """
  Gets a single user.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  @spec get_user(String.t() | non_neg_integer(), Keyword.t()) :: User.t() | nil
  def get_user(id, opts \\ []) do
    User
    |> maybe_include_deactivated(opts)
    |> Repo.get(id)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(String.t() | non_neg_integer, Keyword.t()) :: User.t() | no_return()
  def get_user!(id, opts \\ []) do
    User
    |> maybe_include_deactivated(opts)
    |> Repo.get!(id)
  end

  @doc """
  Gets a user by its username.

  ## Examples

      iex> get_user_by_username("user123")
      %User{}

      iex> get_user_by_username("user456")
      nil

  """
  @spec get_user_by_username(String.t(), Keyword.t()) :: User.t() | nil
  def get_user_by_username(username, opts \\ []), do: get_user_by([username: username], opts)

  @doc """
  Gets a user by its username.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user_by_username!("user123")
      %User{}

      iex> get_user_by_username!("user456")
      ** (Ecto.NoResultsError)

  """
  @spec get_user_by_username!(String.t(), Keyword.t()) :: User.t() | no_return()
  def get_user_by_username!(username, opts \\ []), do: get_user_by!([username: username], opts)

  @doc """
  Gets a user by its email.

  ## Examples

      iex> get_user_by_email("user@example.com")
      %User{}

      iex> get_user_by_email("user@example.com")
      nil

  """
  @spec get_user_by_email(String.t(), Keyword.t()) :: User.t() | nil
  def get_user_by_email(email, opts \\ []), do: get_user_by([email: email], opts)

  @doc """
  Gets a user by its email.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user_by_email!("user@example.com")
      %User{}

      iex> get_user_by_email!("user@example.com")
      ** (Ecto.NoResultsError)

  """
  @spec get_user_by_email!(String.t(), Keyword.t()) :: User.t() | no_return()
  def get_user_by_email!(email, opts \\ []), do: get_user_by!([email: email], opts)

  @doc """
  Gets a user by given clauses.
  """
  @spec get_user_by(Keyword.t(), Keyword.t()) :: User.t() | nil
  def get_user_by(clauses, opts \\ []) do
    User
    |> maybe_include_deactivated(opts)
    |> Repo.get_by(clauses)
  end

  @spec get_user_by!(Keyword.t(), Keyword.t()) :: User.t() | no_return()
  def get_user_by!(clauses, opts \\ []) do
    User
    |> maybe_include_deactivated(opts)
    |> Repo.get_by!(clauses)
  end

  @doc """
  Gets a user by its social login.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user_by_social_login!(:facebook, 123)
      %User{}

      iex> get_user_by_social_login!(:google, 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user_by_social_login!(social_credentials(), Keyword.t()) :: User.t() | no_return()
  def get_user_by_social_login!({provider, uid}, opts \\ []) do
    User
    |> maybe_include_deactivated(opts)
    |> join(:inner, [u], sl in assoc(u, :social_logins))
    |> where([..., sl], sl.provider == ^provider and sl.uid == ^uid)
    |> Repo.one!()
  end

  @doc """
  Gets the user count.

  ## Examples

      iex> user_count()
      42

  """
  @spec user_count(Keyword.t()) :: non_neg_integer()
  def user_count(opts \\ []) do
    User
    |> maybe_include_deactivated(opts)
    |> Repo.aggregate(:count, :id)
  end

  @spec maybe_include_deactivated(Ecto.Queryable.t(), Keyword.t()) :: Ecto.Queryable.t()
  defp maybe_include_deactivated(query, opts) do
    opts
    |> Keyword.get(:include_deactivated, false)
    |> do_maybe_include_deactivated(query)
  end

  @spec do_maybe_include_deactivated(boolean(), Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp do_maybe_include_deactivated(false, query), do: User.active(query)
  defp do_maybe_include_deactivated(true, query), do: query

  @spec member?(User.t()) :: boolean()
  def member?(%User{}), do: false

  @doc """
  Returns `true` if the user has enabled notifications for
  when one of their stories is starred.

  ## Examples

      iex> starred_story_notifications_enabled(%User{})
      true

  """
  @spec starred_story_notifications_enabled?(User.t()) :: boolean()
  def starred_story_notifications_enabled?(%User{settings: settings}) do
    settings.notifications.starred_story
  end

  @doc """
  Inserts a user.
  TODO: Refactor to use Ecto.Multi and send email when creating user.

  ## Examples

      iex> insert_user(attrs)
      {:ok, %User{}}

      iex> insert_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec insert_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def insert_user(attrs) do
    attrs
    |> User.changeset()
    |> Repo.insert()
  end

  @doc """
  Inserts a user.

  Raises `Ecto.InvalidChangesetError` if the attributes are invalid.

  ## Examples

      iex> insert_user!(attrs)
      %User{}

      iex> insert_user!(bad_attrs)
      ** (Ecto.InvalidChangesetError)

  """
  @spec insert_user!(map()) :: User.t() | no_return()
  def insert_user!(attrs) do
    attrs
    |> User.changeset()
    |> Repo.insert!()
  end

  @spec form_username_from_email(String.t()) :: String.t()
  defp form_username_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
  end

  @doc """
  Gets or inserts a user by given email.

  If there's a user with that email, return it.
  Otherwise, insert a user with that email.

  When inserting the user, we try to set its username
  to the part before the `@` in the email.
  If it's already taken we take a UUID.
  """
  @spec get_or_insert_user(String.t(), map()) :: {:ok, User.t()} | {:error, any()}
  def get_or_insert_user(email, attrs \\ %{}) do
    email
    |> get_user_by_email(include_deactivated: true)
    |> do_get_or_insert_user(email, attrs)
  end

  @spec do_get_or_insert_user(User.t() | nil, String.t(), map()) ::
          {:ok, User.t()} | {:error, any()}
  defp do_get_or_insert_user(%User{} = user, _email, _attrs), do: {:ok, user}

  defp do_get_or_insert_user(nil, email, attrs) do
    username_from_email = form_username_from_email(email)

    username =
      if eligible_username?(username_from_email) do
        username_from_email
      else
        UUID.uuid4()
      end

    attrs
    |> Map.put(:username, username)
    |> Map.put(:email, email)
    |> insert_user()
  end

  @spec get_or_insert_user!(String.t(), map()) :: User.t() | no_return()
  def get_or_insert_user!(email, attrs \\ %{}) do
    case get_or_insert_user(email, attrs) do
      {:ok, user} ->
        user

      {:error, reason} ->
        raise """
        cannot get or insert user.
        Reason: #{inspect(reason)}
        """
    end
  end

  @doc """
  Returns `true` if the username is available to use.
  `false` otherwise.
  """
  @spec available_username?(String.t()) :: boolean()
  def available_username?(username),
    do: !get_user_by_username(username, include_deactivated: true)

  @doc """
  Returns `true` if the username is eligible to use.
  `false` otherwise.

  For a username to be eligible it has to be available and have a valid format.
  """
  @spec eligible_username?(String.t()) :: boolean()
  def eligible_username?(username),
    do: available_username?(username) and User.valid_username?(username)

  @doc """
  Returns `true` if the email is available to use.
  `false` otherwise.
  """
  @spec available_email?(String.t()) :: boolean()
  def available_email?(email), do: !get_user_by_email(email, include_deactivated: true)

  @doc """
  Updates a user.
  """
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Verifies the email of a user with a unverified email.
  """
  @spec verify_email(User.t()) :: {:ok, User.t()} | any()
  def verify_email(%User{unverified_email: email} = user) when not is_nil(email) do
    attrs = %{email: email, unverified_email: nil}

    update_user(user, attrs)
  end

  @doc """
  Activates a user.

  If the user was not deactivated it doesn't do anything.
  """
  @spec activate_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def activate_user(%User{} = user) do
    update_user(user, %{deactivated_at: nil})
  end

  @doc """
  Activates a user.
  """
  @spec activate_user!(User.t()) :: User.t() | no_return()
  def activate_user!(%User{} = user) do
    case activate_user(user) do
      {:ok, user} ->
        user

      {:error, reason} ->
        raise """
        cannot activate user.
        Reason: #{inspect(reason)}
        """
    end
  end

  @doc """
  Deletes a user.
  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{} = user), do: Repo.delete(user)

  @doc """
  Marks a user for deletion.

  Enqueues a task that deletes the account and all its content
  after the specified time has passed.
  """
  def mark_user_for_deletion(%User{id: user_id} = user) do
    user_changeset = User.update_changeset(user, %{})

    # 15 days.
    seconds_before_deletion = 60 * 60 * 24 * 15

    schedule_deletion = fn _ ->
      Exq.enqueue_in(
        Exq,
        "user_deletion",
        seconds_before_deletion,
        Margaret.Workers.DeleteAccount,
        [user_id]
      )
    end

    Multi.new()
    |> Multi.update(:deactivate_user, user_changeset)
    |> Multi.run(:schedule_deletion, schedule_deletion)
    |> Repo.transaction()
  end

  @doc """
  Inserts a social login.

  ## Examples

      iex> insert_social_login(attrs)
      {:ok, %SocialLogin{}}

      iex> insert_social_login(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec insert_social_login(map()) :: {:error, Ecto.Changeset.t()} | {:ok, SocialLogin.t()}
  def insert_social_login(attrs) do
    attrs
    |> SocialLogin.changeset()
    |> Repo.insert()
  end

  @doc """
  Inserts a social login.

  Raises `Ecto.InvalidChangesetError` if the attributes are invalid.

  ## Examples

      iex> insert_social_login!(attrs)
      {:ok, %SocialLogin{}}

      iex> insert_social_login!(bad_attrs)
      ** (Ecto.InvalidChangesetError)

  """
  @spec insert_social_login!(map()) :: SocialLogin.t()
  def insert_social_login!(attrs) do
    attrs
    |> SocialLogin.changeset()
    |> Repo.insert!()
  end

  @doc """
  Links a social login to a user.
  """
  @spec link_social_login_to_user(User.t(), social_credentials()) ::
          {:ok, SocialLogin.t()} | {:error, Ecto.Changeset.t()}
  def link_social_login_to_user(%User{id: user_id}, {provider, uid}) do
    attrs = %{user_id: user_id, provider: provider, uid: uid}

    insert_social_login(attrs)
  end

  @spec link_social_login_to_user!(User.t(), social_credentials()) ::
          SocialLogin.t() | no_return()
  def link_social_login_to_user!(%User{} = user, social_info) do
    case link_social_login_to_user(user, social_info) do
      {:ok, social_login} ->
        social_login

      {:error, reason} ->
        raise """
        cannot link user to social login.
        Reason: #{inspect(reason)}
        """
    end
  end

  @doc """
  Gets the story count of a user.
  Accepts the option `published_only: true`
  which only counts pubilshed stories.

  ## Examples

      iex> story_count(%User{})
      42

      iex> story_count(%User{}, published_only: true)
      0

  """
  @spec story_count(User.t(), Keyword.t()) :: non_neg_integer()
  def story_count(%User{} = author, opts \\ []) do
    query =
      if Keyword.get(opts, :published_only, false) do
        Story.published()
      else
        Story
      end
      |> Story.by_author(author)

    Repo.aggregate(query, :count, :id)
  end

  @doc """
  Gets the follower count of a user.

  ## Examples

      iex> follower_count(%User{})
      42

      iex> follower_count(%User{})
      0

  """
  @spec follower_count(User.t()) :: non_neg_integer()
  def follower_count(%User{} = user), do: Follows.follower_count(user: user)

  @doc """
  Gets the publication count of the user.

  ## Examples

      iex> publication_count(%User{})
      42

      iex> publication_count(%User{})
      0

  """
  @spec publication_count(User.t()) :: non_neg_integer()
  def publication_count(%User{} = user) do
    query = PublicationMembership.by_member(user)

    Repo.aggregate(query, :count, :id)
  end
end
