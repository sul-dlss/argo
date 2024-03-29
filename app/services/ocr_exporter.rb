# frozen_string_literal: true

# This exports OCR files that are in preservation for a provided list of barcodes
# This is used by researchers who want to get a dump of OCR files from the google books project
# The OCR files for a book are zipped.
class OCRExporter
  # @param [String] filename the input file name
  # @param [String] directory the output directory path
  def self.export(filename, directory)
    new(filename, directory).export
  end

  # @param [String] filename the input file name
  # @param [String] directory the output directory path
  def initialize(filename, directory, finder: DruidFinder.new)
    @filename = filename
    @directory = directory
    @finder = finder
  end

  def export
    File.open(filename, 'r').each do |line|
      druid = finder.find_druid(line.chomp)
      unless druid
        warn("no druid found for #{line.chomp}")
        next
      end

      obj = Repository.find(druid)
      Downloader.new(directory, druid, obj.version, filenames(obj)).download_files
    end
  end

  private

  attr_reader :filename, :directory, :finder

  def filenames(object)
    Array(object.structural&.contains).flat_map do |file_set|
      file_set.structural.contains.filter { |file| file.filename.match?(/-gb-txt.zip/) }.map(&:filename)
    end
  end

  class Downloader
    def initialize(directory, id, version, filenames)
      @directory = directory
      @id = id
      @version = version
      @filenames = filenames
    end

    def download_files
      FileUtils.mkdir File.join(@directory, @id)
      @filenames.each do |filename|
        File.open(File.join(@directory, @id, filename), 'wb') do |f|
          f.puts Preservation::Client.objects.content(druid: @id, filepath: filename, version: @version)
        end
      end
    end
  end

  class DruidFinder
    # This searches Solr for a barcode tag
    def find_druid(barcode)
      resp = repository.search(
        rows: 1,
        fl: 'id',
        fq: "tag_ssim:\"barcode : #{barcode}\""
      )['response']['docs']
      return unless resp.any?

      resp.first['id']
    end

    delegate :repository, to: :blacklight_config

    def blacklight_config
      @blacklight_config ||= CatalogController.blacklight_config.configure
    end
  end
end
