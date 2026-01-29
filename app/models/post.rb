# frozen_string_literal: true

class Post < ApplicationRecord
  has_rich_text :body

  validates :title, presence: true

  scope :kept, -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }

  def discard!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def excerpt(length = 200)
    return "" unless body.present?

    plain = body.to_plain_text.to_s.strip
    return plain if plain.length <= length

    "#{plain[0, length]}..."
  end
end
