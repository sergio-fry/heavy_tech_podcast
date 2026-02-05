# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/posts", type: :request do
  let(:valid_attributes) { { title: "A post", body: "Body content" } }
  let(:invalid_attributes) { { title: "" } }

  describe "GET / (root)" do
    it "renders the main page with posts list" do
      get root_url
      expect(response).to be_successful
      expect(response.body).to include("Posts")
    end
  end

  describe "GET /index" do
    it "renders a successful response" do
      Article.create! valid_attributes
      get posts_url
      expect(response).to be_successful
    end

    it "renders post title as h2, excerpt and publication date" do
      post_record = Article.create!(title: "My Post", body: "First 200 chars or so of the article body here.")
      get posts_url
      expect(response).to be_successful
      expect(response.body).to include("My Post")
      expect(response.body).to include("First 200 chars")
      expect(response.body).to match(/<h2[^>]*>/)
      expect(response.body).to include(post_record.created_at.strftime("%d"))
    end

    it "returns only kept posts" do
      Article.create!(title: "Kept")
      Article.create!(title: "Discarded", deleted_at: 1.day.ago)
      get posts_url
      expect(response).to be_successful
      expect(response.body).to include("Kept")
      expect(response.body).not_to include("Discarded")
    end

    it "filters by type=article" do
      Article.create!(title: "An Article")
      episode = Episode.new(title: "An Episode")
      episode.audio_file.attach(io: StringIO.new("x"), filename: "x.mp3", content_type: "audio/mpeg")
      allow_any_instance_of(ActiveStorage::Blob).to receive(:open) do |&block|
        Tempfile.create([ "t", ".mp3" ]) { |f| f.write("x"); f.rewind; block.call(f) }
      end
      allow(Mp3Info).to receive(:open).and_yield(double(length: 60.0))
      episode.save!
      get posts_url, params: { type: "article" }
      expect(response).to be_successful
      expect(response.body).to include("An Article")
      expect(response.body).not_to include("An Episode")
    end

    it "filters by type=episode" do
      Article.create!(title: "An Article")
      episode = Episode.new(title: "An Episode")
      episode.audio_file.attach(io: StringIO.new("x"), filename: "x.mp3", content_type: "audio/mpeg")
      allow_any_instance_of(ActiveStorage::Blob).to receive(:open) do |&block|
        Tempfile.create([ "t", ".mp3" ]) { |f| f.write("x"); f.rewind; block.call(f) }
      end
      allow(Mp3Info).to receive(:open).and_yield(double(length: 60.0))
      episode.save!
      get posts_url, params: { type: "episode" }
      expect(response).to be_successful
      expect(response.body).to include("An Episode")
      expect(response.body).not_to include("An Article")
    end
  end

  describe "GET /trash" do
    it "returns only discarded posts" do
      Article.create!(title: "Discarded", deleted_at: 1.day.ago)
      Article.create!(title: "Kept")
      get trash_posts_url
      expect(response).to be_successful
      expect(response.body).to include("Discarded")
      expect(response.body).not_to include("Kept")
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      post_record = Article.create! valid_attributes
      get post_url(post_record)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response (default Article)" do
      get new_post_url
      expect(response).to be_successful
      expect(response.body).to include("New Article")
    end

    it "renders new episode form for new/:type" do
      get new_typed_posts_url(type: "episode")
      expect(response).to be_successful
      expect(response.body).to include("New Episode")
    end

    it "renders new article form for new/article" do
      get new_typed_posts_url(type: "article")
      expect(response).to be_successful
      expect(response.body).to include("New Article")
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      post_record = Article.create! valid_attributes
      get edit_post_url(post_record)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters (Article)" do
      it "creates a new Article" do
        expect {
          post posts_url, params: { post: valid_attributes.merge(type: "Article") }
        }.to change(Article, :count).by(1)
      end

      it "redirects to the created post" do
        post posts_url, params: { post: valid_attributes.merge(type: "Article") }
        expect(response).to redirect_to(post_url(Post.last))
      end
    end

    context "when params are under model name (article) instead of :post" do
      it "returns 400 and does not create a post (reproduces UI bug without scope: :post)" do
        expect {
          post posts_url, params: { article: { type: "Article", title: "New", body: "Body" } }
        }.not_to change(Post, :count)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Post" do
        expect {
          post posts_url, params: { post: invalid_attributes }
        }.not_to change(Post, :count)
      end

      it "renders a response with 422 status" do
        post posts_url, params: { post: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) { { title: "Updated title" } }

      it "updates the requested post" do
        post_record = Article.create! valid_attributes
        patch post_url(post_record), params: { post: new_attributes }
        post_record.reload
        expect(post_record.title).to eq("Updated title")
      end

      it "redirects to the post" do
        post_record = Article.create! valid_attributes
        patch post_url(post_record), params: { post: new_attributes }
        expect(response).to redirect_to(post_url(post_record))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        post_record = Article.create! valid_attributes
        patch post_url(post_record), params: { post: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "soft-deletes the post (removes from kept)" do
      post_record = Article.create! valid_attributes
      expect {
        delete post_url(post_record)
      }.to change { Post.kept.count }.by(-1)
    end

    it "does not destroy the record" do
      post_record = Article.create! valid_attributes
      expect {
        delete post_url(post_record)
      }.not_to change(Post, :count)
    end

    it "redirects to the posts list" do
      post_record = Article.create! valid_attributes
      delete post_url(post_record)
      expect(response).to redirect_to(posts_url)
    end
  end

  describe "POST /restore" do
    it "restores the post and redirects to posts" do
      post_record = Article.create!(title: "Post", deleted_at: 1.day.ago)
      expect {
        post restore_post_url(post_record)
      }.to change { Post.kept.count }.by(1)

      expect(response).to redirect_to(posts_url)
      post_record.reload
      expect(post_record.deleted_at).to be_nil
    end
  end
end
