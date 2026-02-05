# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :set_post_for_restore, only: %i[ restore ]

  # GET /posts or /posts.json
  def index
    scope = Post.kept.order(created_at: :desc)
    scope = scope.where(type: type_filter) if type_filter.present?
    @posts = scope
  end

  # GET /posts/trash
  def trash
    @posts = Post.discarded.order(deleted_at: :desc)
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = post_class_for_new.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    klass = post_class_for_create
    @post = klass.new(post_params.except(:type).merge(type: klass.name))

    respond_to do |format|
      if @post.save
        format.html { redirect_to post_path(@post), notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: post_url(@post) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params.except(:type))
        format.html { redirect_to post_path(@post), notice: "Post was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: post_url(@post) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json (soft delete)
  def destroy
    @post.discard!

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /posts/1/restore
  def restore
    @post.restore!

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully restored.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_post
    @post = Post.kept.find(params.expect(:id))
  end

  def set_post_for_restore
    @post = Post.discarded.find(params.expect(:id))
  end

  def post_params
    params.expect(post: [ :type, :title, :body, :audio_file ])
  end

  def type_filter
    return nil if params[:type].blank?

    case params[:type].to_s.downcase
    when "article" then "Article"
    when "episode" then "Episode"
    else nil
    end
  end

  def post_class_for_new
    case params[:type].to_s.downcase
    when "episode" then Episode
    else Article
    end
  end

  def post_class_for_create
    type = post_params[:type].to_s
    type.presence_in(%w[ Article Episode ]) ? type.constantize : Article
  end
end
