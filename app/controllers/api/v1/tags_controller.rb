class Api::V1::TagsController < ApplicationController
  before_action :set_tag, only: %i[ show update destroy ]
  after_action :filter_unused_tags

  # GET /tags
  def index
    @tags = Tag.all

    render json: @tags
  end

  # GET /tags/1
  def show
    @tag = Tag.find(params[:id])
    render json: @tag
  end

  # POST /tags
  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      render json: @tag, status: :created, location: @tag
    else
      render json: @tag.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tags/1
  def update
    if @tag.update(tag_params)
      render json: @tag
    else
      render json: @tag.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tags/1
  def destroy
    @tag.destroy
  end

  private

  #Delete unused tags
  def filter_unused_tags
    @tags = Tag.all
    @taggables = Taggable.all
    @tags.each do |tag|
      if !@taggables.exists?(tag_id: tag.id)
        tag.destroy
      end
    end
  end

  def set_tag
    @tag = Tag.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tag_params
    params.require(:tag).permit(:name)
  end
end
