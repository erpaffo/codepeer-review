class HistoryRecordsController < ApplicationController
  def index
    @snippet = Snippet.find(params[:snippet_id])
    # Filtra i record per escludere quelli con il campo 'updated_at'
    @history_records = @snippet.history_records.where.not(field: 'updated_at').order(created_at: :desc)
  end
end
