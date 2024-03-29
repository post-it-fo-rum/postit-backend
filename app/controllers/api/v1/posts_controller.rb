class Api::V1::PostsController < ApplicationController
  before_action :set_post, only: %i[ show update destroy ]

  # GET /posts
  # json response is modified to deal with multiple-level relations
  def index
    @posts = Post.all
    render json: @posts, each_serializer: PostSerializer, include: ["comments", "comments.user", "user", "tags"]
  end

  # GET /posts/1
  def show
    @post = Post.find(params[:id])
    render json: @post
  end

  # GET /posts/current_user

  def showByCurrentUser
    @posts = Post.where(user_id: session[:user_id]).all
    render json: @posts, each_serializer: PostSerializer, include: ["comments", "comments.user", "user", "tags"]
  end

  # GET /posts/tags/1

  def showByTag
    @tag = Tag.find(params[:id])
    @taggables = @tag.taggables.where(tag_id: params[:id])
    @post_ids = @taggables.pluck(:post_id)
    @posts = Post.find(@post_ids)
    render json: @posts, each_serializer: PostSerializer, include: ["comments", "comments.user", "user", "tags"]
  end

  # POST /posts
  def create
    @post = self.current_user.posts.build(post_params.except(:tags))
    create_or_delete_posts_tags(@post, params[:post][:tags])
    if @post.save
      render json: {
        post: PostSerializer.new(@post),
      }
    else
      render json: {
        status: 500,
        error: @post.errors.full_messages,
      }
    end
  end

  # PATCH/PUT /posts/1

  def update
    create_or_delete_posts_tags(@post, params[:post][:tags])

    if @post.update(post_params.except(:tags))
      render json: @post
    else
      render json: {
        status: 500,
        error: @post.errors.full_messages,
      }
    end
  end

  # DELETE /posts/1
  def destroy
    unless @post.user == self.current_user
      render json: {
        status: 500,
        error: @post.errors.full_messages,
      }
    end

    @post.destroy
    render json: @post
  end

  private

=begin
This method is referenced from https://www.youtube.com/watch?v=03enr4NNgLI
=end

  # Create or delete related tags when user creates or edits a post
  def create_or_delete_posts_tags(post, tags)
    post.taggables.destroy_all
    tags.each do |tag|
      post.tags << Tag.find_or_create_by(name: tag[:name])
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def post_params
    params.require(:post).permit(:id, :title, :body, :likes, :user_id, :avatar, { tags: [:name] })
  end
end
