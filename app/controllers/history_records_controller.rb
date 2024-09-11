class HistoryRecordsController < ApplicationController
  def index
    @snippet = Snippet.find(params[:snippet_id])
    @history_records = @snippet.history_records.where.not(field: 'updated_at').order(created_at: :desc)
  end


  def show_previous
    @snippet = Snippet.find(params[:snippet_id])
    @history_record = @snippet.history_records.find(params[:id])


    @previous_snippet = @snippet.dup


    @snippet.history_records.where('created_at <= ?', @history_record.created_at).each do |record|
      case record.field
      when 'title'
        @previous_snippet.title = record.old_value
      when 'content'
        @previous_snippet.content = record.old_value
      when 'comment'
        @previous_snippet.comment = record.old_value
      end
    end

    render 'show_previous'
  end

  private

  def set_snippet
    @snippet = Snippet.find(params[:snippet_id])
  end

  def build_previous_snippet(history_record)
    snippet = @snippet.dup
    snippet.title = history_record.field == 'title' ? history_record.old_value : snippet.title
    snippet.content = history_record.field == 'content' ? history_record.old_value : snippet.content
    snippet.comment = history_record.field == 'comment' ? history_record.old_value : snippet.comment
    snippet
  end

end
