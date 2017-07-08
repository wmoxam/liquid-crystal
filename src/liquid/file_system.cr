module Liquid
  # A Liquid file system is way to let your templates retrieve other templates
  # for use with the include tag.
  #
  # You can implement subclasses that retrieve templates from the database,
  # from the file system using a different path structure, you can provide
  # them as hard-coded inline strings, or any manner that you see fit.
  #
  # You can add additional instance variables, arguments, or methods as needed.
  #
  # Example:
  #
  # Liquid::Template.file_system = Liquid::LocalFileSystem.new(template_path)
  # liquid = Liquid::Template.parse(template)
  #

  class FileSystem
    def to_liquid
      # for duck-typing with Liquid::Type
    end

    def read_template_file(template_path, context)
    end
  end

  # This will parse the template with a LocalFileSystem implementation rooted
  # at 'template_path'.
  class BlankFileSystem < FileSystem
    # Called by Liquid to retrieve a template file
    def read_template_file(template_path, context)
      raise FileSystemError.new "This liquid context does not allow includes."
    end
  end

  # This implements an abstract file system which retrieves template files
  # named in a manner similar to Rails partials,
  # ie. with the template name prefixed with an underscore. The extension
  # ".liquid" is also added.
  #
  # For security reasons, template paths are only allowed to contain letters,
  # numbers, and underscore.
  #
  # Example:
  #
  # file_system = Liquid::LocalFileSystem.new("/some/path")
  #
  # file_system.full_path("mypartial")     # => "/some/path/_mypartial.liquid"
  # file_system.full_path("dir/mypartial") # => "/some/path/dir/_mypartial.liquid"
  #
  class LocalFileSystem < FileSystem
    property root : String

    def initialize(root)
      @root = root
    end

    def read_template_file(template_path, context)
      full_path = full_path(template_path.to_s)
      unless File.exists?(full_path)
        raise FileSystemError.new "No such template '#{template_path}'"
      end

      File.read(full_path)
    end

    def full_path(template_path)
      unless template_path =~ /^[^.\/][a-zA-Z0-9_\/]+$/
        raise FileSystemError.new "Illegal template name '#{template_path}'"
      end

      full_path = if template_path.includes?("/")
        File.join(root,
                  File.dirname(template_path),
                  "_#{File.basename(template_path)}.liquid")
      else
        File.join(root, "_#{template_path}.liquid")
      end

      unless File.expand_path(full_path) =~ /^#{File.expand_path(root)}/
        raise FileSystemError.new "Illegal template path " \
          "'#{File.expand_path(full_path)}'"
      end

      full_path
    end
  end
end
