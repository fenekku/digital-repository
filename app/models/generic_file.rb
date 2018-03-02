class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include InstitutionalCollectionPermissions
  include CleanAttributeValues
  include EzidGenerator
  include Galtersufia::GenericFile::FullTextIndexing
  include Galtersufia::GenericFile::MimeTypes

  belongs_to :parent,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
    class_name: "Collection"

  belongs_to :combined_file,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasEquivalent,
    class_name: "Collection"

  property :abstract, predicate: ::RDF::DC.abstract, multiple: true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :acknowledgments,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/acknowledgments'),
           :multiple => true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :grants_and_funding,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/grants_and_funding'),
           :multiple => true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :digital_origin, predicate: ::RDF::Vocab::MODS.digitalOrigin, multiple: true do |index|
    index.as :stored_searchable
  end

  property :mesh, predicate: ::RDF::DC.MESH, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :lcsh, predicate: ::RDF::DC.LCSH, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_geographic,
           :predicate => ::RDF::URI.new(
             'http://id.worldcat.org/fast/ontology/1.0/#facet-Geographic'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :subject_name,
           :predicate => ::RDF::URI.new('http://id.loc.gov/authorities/names'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :page_number,
           :predicate => ::RDF::URI.new(
             'http://www.w3.org/TR/xmlschema-2/#string'),
           :multiple => false do |index|
    index.as :stored_searchable
    index.type :string
  end

  property :page_number_actual,
           :predicate => ::RDF::URI.new(
             'http://www.w3.org/TR/xmlschema-2/#integer'),
           :multiple => false do |index|
    index.as :stored_sortable
    index.type :integer
  end

  property :doi,
           :predicate => ::RDF::Vocab::Bibframe.doi,
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :ark,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/ark'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :original_publisher,
           :predicate => ::RDF::URI.new(
             'http://vivoweb.org/ontology/core#publisher'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :private_note,
           :predicate => ::RDF::Vocab::MODS.note,
           :multiple => true do |index|
    index.type :text
    index.as :stored_searchable
  end

  before_save :store_the_actual_page_number

  def store_the_actual_page_number
    if self.page_number_actual_changed?
      self.page_number_actual = Integer(page_number_actual) rescue nil
    elsif self.page_number_changed?
      self.page_number_actual = Integer(page_number) rescue nil
    end
  end
  protected :store_the_actual_page_number

  def all_tags
    mesh + lcsh + subject_name + subject_geographic + subject + tag
  end

  def add_doi_to_citation(citation)
    if doi.first.present?
      the_doi = doi.first.to_s.gsub('doi:', '')
      citation.gsub!(/ +$/, '')
      citation << " <a href='https://doi.org/#{the_doi}'>doi:#{the_doi}</a>"
    end
    citation.html_safe
  end
  private :add_doi_to_citation

  def export_as_apa_citation
    citation = super
    add_doi_to_citation(citation)
  end

  def export_as_mla_citation
    citation = super
    add_doi_to_citation(citation)
  end

  def export_as_chicago_citation
    citation = super
    add_doi_to_citation(citation)
  end

  def parent_collections_followers(&block)
    pairs = collection_ids.map {|col_id|
      Follow.where(followable_fedora_id: col_id,
                   followable_type: 'Collection').map do |o|
        raise "Non-User follower for #{col.id}" unless o.follower_type == 'User'
        [Collection.find(col_id), User.find(o.follower_id)]
      end
    }.flatten(1)
     .sort_by {|pair| pair.first.title }
     .each {|col, follower| block.call(col, follower) }
  end

  class << self
    def indexer
      Sufia::GalterGenericFileIndexingService
    end
  end
end
