# frozen_string_literal: true

require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it "is invalid without a title" do
      post = described_class.new(title: nil)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "is valid with a title" do
      post = described_class.new(title: "A post")
      expect(post).to be_valid
    end
  end

  describe "scopes" do
    describe ".kept" do
      it "includes records with deleted_at nil" do
        kept_post = described_class.create!(title: "Kept")
        expect(described_class.kept).to include(kept_post)
      end

      it "excludes records with deleted_at set" do
        discarded_post = described_class.create!(title: "Discarded", deleted_at: 1.day.ago)
        expect(described_class.kept).not_to include(discarded_post)
      end
    end

    describe ".discarded" do
      it "includes records with deleted_at set" do
        discarded_post = described_class.create!(title: "Discarded", deleted_at: 1.day.ago)
        expect(described_class.discarded).to include(discarded_post)
      end

      it "excludes records with deleted_at nil" do
        kept_post = described_class.create!(title: "Kept")
        expect(described_class.discarded).not_to include(kept_post)
      end
    end
  end

  describe "#discard!" do
    it "sets deleted_at" do
      post = described_class.create!(title: "Post")
      expect { post.discard! }.to change { post.reload.deleted_at }.from(nil).to(be_within(2.seconds).of(Time.current))
    end
  end

  describe "#restore!" do
    it "clears deleted_at" do
      post = described_class.create!(title: "Post", deleted_at: 1.day.ago)
      expect { post.restore! }.to change { post.reload.deleted_at }.to(nil)
    end
  end

  describe "#excerpt" do
    it "returns empty string when body is blank" do
      post = described_class.create!(title: "Post")
      expect(post.excerpt).to eq("")
    end

    it "returns full text when body is shorter than length" do
      short = "Short text."
      post = described_class.create!(title: "Post", body: short)
      expect(post.excerpt(200)).to eq(short)
    end

    it "truncates to given length and appends ellipsis when body is longer" do
      long = "a" * 250
      post = described_class.create!(title: "Post", body: long)
      expect(post.excerpt(200)).to eq("a" * 200 + "...")
      expect(post.excerpt(200).length).to eq(203)
    end

    it "returns plain text without HTML" do
      post = described_class.create!(title: "Post", body: "<p>Hello <strong>world</strong>!</p>")
      expect(post.excerpt(50)).to eq("Hello world!")
    end
  end
end
