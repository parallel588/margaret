defmodule Margaret.Repo.Migrations.AddPublicationTagsTable do
  @moduledoc false

  use Ecto.Migration

  @doc false
  def change do
    create table(:publication_tags, primary_key: false) do
      add(
        :publication_id,
        references(:publications, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(:tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true)
    end
  end
end
