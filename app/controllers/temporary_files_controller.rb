class TemporaryFilesController < ApplicationController
  def create
    temp_file = TemporaryFile.new(file: params[:file])

    if temp_file.save
      render json: { message: "File uploaded successfully", file_id: temp_file.id }, status: :ok
    else
      render json: { error: temp_file.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    temp_file = TemporaryFile.find(params[:id])
    temp_file.destroy
    render json: { message: "File deleted successfully" }, status: :ok
  end
end
