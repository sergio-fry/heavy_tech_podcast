# frozen_string_literal: true

require "mp3info"

class Episode < Post
  has_one_attached :audio_file

  validates :audio_file, presence: true
  validate :audio_file_format

  after_save :extract_audio_metadata, if: :should_extract_audio_metadata?

  ALLOWED_AUDIO_TYPES = %w[ audio/mpeg audio/mp3 ].freeze

  private

  def audio_file_format
    return unless audio_file.attached?

    unless audio_file.content_type.in?(ALLOWED_AUDIO_TYPES)
      errors.add(:audio_file, "must be an MP3 file")
    end
  end

  def should_extract_audio_metadata?
    audio_file.attached? && duration_seconds.nil?
  end

  def extract_audio_metadata
    return unless audio_file.attached?

    audio_file.blob.open do |tempfile|
      Mp3Info.open(tempfile.path) do |mp3|
        update_columns(
          duration_seconds: mp3.length.to_i,
          audio_mime_type: audio_file.content_type
        )
      end
    end
  rescue Mp3InfoError => e
    Rails.logger.warn("Episode#extract_audio_metadata failed: #{e.message}")
  end
end
