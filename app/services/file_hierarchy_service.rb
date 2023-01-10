# frozen_string_literal: true

# Arranges Cocina Files into a hierarchy of directories and files.
class FileHierarchyService
  File = Struct.new(:name, :size) do
    def file?
      true
    end

    def directory?
      false
    end
  end

  Directory = Struct.new(:name, :children_directories, :children_files, :index) do
    def file?
      false
    end

    def directory?
      true
    end
  end

  def self.to_hierarchy(cocina_object:)
    new(cocina_object: cocina_object).to_hierarchy
  end

  def initialize(cocina_object:)
    @cocina_object = cocina_object
    @index = 0
    @root_directory = Directory.new("", [], [], next_index)
  end

  def to_hierarchy
    cocina_files.each { |cocina_file| add_to_hierarchy(cocina_file) }
    root_directory
  end

  private

  attr_reader :cocina_object, :root_directory

  def next_index
    @index += 1
  end

  def cocina_files
    cocina_object.structural.contains.flat_map do |file_set|
      file_set.structural.contains
    end
  end

  def add_to_hierarchy(cocina_file)
    paths = cocina_file.filename.split("/")
    filename = paths.pop

    directory = directory_for(paths, root_directory)
    directory.children_files << File.new(filename, cocina_file.size)
  end

  def directory_for(paths, directory)
    return directory if paths.empty?

    path = paths.shift
    child_directory = directory.children_directories.find { |child_directory| child_directory.name == path }
    unless child_directory
      child_directory = Directory.new(path, [], [], next_index)
      directory.children_directories << child_directory
    end

    return child_directory if paths.empty?

    directory_for(paths, child_directory)
  end
end
