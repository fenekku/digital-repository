module Galtersufia::GenericFile
  extend ActiveSupport::Autoload

  module FullTextIndexing
    extend ActiveSupport::Concern
    include Sufia::GenericFile::FullTextIndexing

    private

    def extract_content
      return if content.size.to_i > 10.megabyte
      return if resource_type.include?('Dataset')
      super
    end
  end
end
