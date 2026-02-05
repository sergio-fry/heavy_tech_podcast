# frozen_string_literal: true

require "rails_helper"

RSpec.describe Episode, type: :model do
  it "inherits from Post" do
    expect(described_class.new).to be_a(Post)
  end

  describe "validations" do
    it "is invalid without audio_file" do
      episode = described_class.new(title: "Episode")
      expect(episode).not_to be_valid
      expect(episode.errors[:audio_file]).to include("can't be blank")
    end

    it "is invalid with non-MP3 content type" do
      episode = described_class.new(title: "Episode")
      episode.audio_file.attach(
        io: StringIO.new("x"),
        filename: "x.pdf",
        content_type: "application/pdf"
      )
      expect(episode).not_to be_valid
      expect(episode.errors[:audio_file]).to include("must be an MP3 file")
    end

    it "is valid with title and MP3 audio_file" do
      episode = described_class.new(title: "Episode")
      episode.audio_file.attach(
        io: StringIO.new("x"),
        filename: "ep.mp3",
        content_type: "audio/mpeg"
      )
      allow(Mp3Info).to receive(:open).and_yield(double(length: 60.0))
      expect(episode).to be_valid
    end
  end

  describe "audio metadata extraction" do
    def stub_blob_open_and_mp3info(length_sec)
      allow_any_instance_of(ActiveStorage::Blob).to receive(:open) do |&block|
        Tempfile.create([ "test", ".mp3" ]) do |f|
          f.write("x")
          f.rewind
          block.call(f)
        end
      end
      allow(Mp3Info).to receive(:open).and_yield(double(length: length_sec))
    end

    it "sets duration_seconds and audio_mime_type after save when audio is attached" do
      episode = described_class.new(title: "Episode")
      episode.audio_file.attach(
        io: StringIO.new("x"),
        filename: "sample.mp3",
        content_type: "audio/mpeg"
      )
      stub_blob_open_and_mp3info(90.5)

      episode.save!

      episode.reload
      expect(episode.duration_seconds).to eq(90)
      expect(episode.audio_mime_type).to eq("audio/mpeg")
    end

    it "does not overwrite duration_seconds on subsequent saves when already set" do
      episode = described_class.new(title: "Episode")
      episode.audio_file.attach(
        io: StringIO.new("x"),
        filename: "sample.mp3",
        content_type: "audio/mpeg"
      )
      stub_blob_open_and_mp3info(120.0)

      episode.save!
      expect(episode.reload.duration_seconds).to eq(120)

      stub_blob_open_and_mp3info(200.0)
      episode.update!(title: "Updated title")
      expect(episode.reload.duration_seconds).to eq(120)
    end
  end

  describe "STI" do
    it "has type Episode" do
      episode = described_class.new(title: "Ep")
      episode.audio_file.attach(
        io: StringIO.new("x"),
        filename: "x.mp3",
        content_type: "audio/mpeg"
      )
      allow_any_instance_of(ActiveStorage::Blob).to receive(:open) do |&block|
        Tempfile.create([ "test", ".mp3" ]) { |f| f.write("x"); f.rewind; block.call(f) }
      end
      allow(Mp3Info).to receive(:open).and_yield(double(length: 1.0))
      episode.save!
      expect(episode.type).to eq("Episode")
      expect(episode).to be_a(Episode)
      expect(episode).to be_a(Post)
    end
  end
end
