require "rails_helper"

RSpec.describe "posts/index", type: :view do
  before do
    assign(:posts, [
      Post.create!(title: "First Post", body: "Excerpt of first post."),
      Post.create!(title: "Second Post", body: "Excerpt of second post.")
    ])
  end

  it "renders a list of posts" do
    render
    expect(rendered).to include("First Post")
    expect(rendered).to include("Second Post")
    expect(rendered).to include("Excerpt of first post.")
    expect(rendered).to include("Excerpt of second post.")
    assert_select "h2", count: 2
    assert_select "div[id^='post_']", count: 2
  end
end
