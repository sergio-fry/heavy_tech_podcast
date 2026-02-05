# frozen_string_literal: true

require "rails_helper"

RSpec.describe Article, type: :model do
  describe "STI" do
    it "has type Article" do
      article = described_class.build(title: "An article")
      expect(article.type).to eq("Article")
    end
  end
end
