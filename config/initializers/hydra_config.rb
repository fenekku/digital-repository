# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

Hydra.configure do |config|
  # This specifies the solr field names of permissions-related fields.
  # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
  # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
  #
  # config.permissions.discover.group       = ActiveFedora::SolrService.solr_name("discover_access_group", :symbol)
  # config.permissions.discover.individual  = ActiveFedora::SolrService.solr_name("discover_access_person", :symbol)
  # config.permissions.read.group           = ActiveFedora::SolrService.solr_name("read_access_group", :symbol)
  # config.permissions.read.individual      = ActiveFedora::SolrService.solr_name("read_access_person", :symbol)
  # config.permissions.edit.group           = ActiveFedora::SolrService.solr_name("edit_access_group", :symbol)
  # config.permissions.edit.individual      = ActiveFedora::SolrService.solr_name("edit_access_person", :symbol)
  #
  # config.permissions.embargo.release_date  = ActiveFedora::SolrService.solr_name("embargo_release_date", :stored_sortable, type: :date)
  # config.permissions.lease.expiration_date = ActiveFedora::SolrService.solr_name("lease_expiration_date", :stored_sortable, type: :date)
  #
  #
  # specify the user model
  # config.user_model = '#{model_name.classify}'
end

Rails.configuration.to_prepare do
  Hydra::Derivatives::Document.timeout = 120
  Hydra::Derivatives::Image.timeout = 90
  Hydra::Derivatives::Jpeg2kImage.timeout = 90

  Hydra::Derivatives::Image.class_eval do
    def create_image(output_file, format, quality=nil)
      xfrm = load_image_transformer
      xfrm.format(format) do |convert|
        convert.merge!(['-alpha', 'remove'])
      end
      yield(xfrm) if block_given?
      xfrm.quality(quality.to_s) if quality
      write_image(output_file, xfrm)
    end
  end

  module Hydra::Derivatives::ShellBasedProcessor
    module ClassMethods
      def execute_without_timeout(command, context)
        stdin, stdout, stderr, wait_thr = popen3(command)
        context[:pid] = wait_thr[:pid]
        stdin.close
        stdout.close
        err = stderr.read
        stderr.close
        raise "Unable to execute command \"#{command}\"\n#{err}" unless wait_thr.value.success?
      end
    end
  end
end
