module Sufia
  class GalterGenericFileIndexingService < GenericFileIndexingService
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('tags', :facetable)] = object.all_tags

        solr_doc[
          Solrizer.solr_name(:width, :type => :integer)
        ] = object.width

        solr_doc[
          Solrizer.solr_name(:height, :type => :integer)
        ] = object.height

        if object.rights.present?
          solr_doc[Solrizer.solr_name('rights', :facetable)] = (
            object.rights.map {|cr| Sufia.config.cc_licenses.key(cr) }
          )
        end
      end
    end
  end
end
