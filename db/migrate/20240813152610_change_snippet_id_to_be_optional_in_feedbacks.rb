class ChangeSnippetIdToBeOptionalInFeedbacks < ActiveRecord::Migration[6.1]
  def change
    change_column_null :feedbacks, :snippet_id, true
  end
end
