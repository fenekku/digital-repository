class GalterCollectionPresenter < Sufia::CollectionPresenter
  self.terms = [
    :resource_type,
    :title,
    :total_items,
    :size,
    :creator,
    :contributor,
    :description,
    :abstract,
    :bibliographic_citation,
    :tag,
    :rights,
    :publisher,
    :date_created,
    :subject,
    :mesh,
    :lcsh,
    :subject_geographic,
    :subject_name,
    :language,
    :identifier,
    :based_near,
    :related_url,
    :digital_origin,
    :page_number
  ]
end
