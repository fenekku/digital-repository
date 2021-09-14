include Sufia::Export

# Convert a GenericFile including metadata, permissions and version metadata into a PORO
# so that the metadata can be exported in json format using to_json
#
class InvenioRdmRecordConverter < Sufia::Export::Converter
  include Galtersufia::GenericFile::InvenioResourceTypeMappings
  include Galtersufia::GenericFile::KnownOrganizations

  SUBJECT_SCHEMES = [:tag, :mesh, :lcsh, :subject_name]
  CIRCA_VALUES = ["ca.", "ca", "circa", "CA.", "CA", "CIRCA"]
  UNDATED = ["undated", "UNDATED"]
  REFERENCE_FIELDS = ["bibliographic_citation", "part_of"]
  ABBR_MONTHNAMES = Date::ABBR_MONTHNAMES.map{ |abbr_monthname| abbr_monthname.downcase if abbr_monthname.present? }
  MONTHNAMES = Date::MONTHNAMES.map{ |monthname| monthname.downcase if monthname.present? }
  SEASONS = ["spring", "summer", "fall", "winter"]
  ENG = "eng"
  ENGLISH = "english"
  ROLE_OTHER = 'role-other'
  OPEN_ACCESS = "open"
  INVENIO_PUBLIC = "public"
  INVENIO_RESTRICTED = "restricted"
  ALL_RIGHTS_RESERVED = 'All rights reserved'
  DOI_ORG = "doi.org/"
  MEMOIZED_PERSON_OR_ORG_DATA_FILE = 'memoized_person_or_org_data.txt'
  FUNDING_DATA_FILE = 'app/models/concerns/galtersufia/generic_file/funding_data.txt'
  LICENSE_DATA_FILE = 'app/models/concerns/galtersufia/generic_file/license_data.txt'

  @@header_lookup ||= HeaderLookup.new
  @@funding_data ||= eval(File.read(FUNDING_DATA_FILE))
  @@person_or_org_data ||= eval(File.read(MEMOIZED_PERSON_OR_ORG_DATA_FILE))
  @@license_data ||= eval(File.read(LICENSE_DATA_FILE))

  # Create an instance of a InvenioRdmRecordConverter converter containing all the metadata for json export
  #
  # @param [GenericFile] generic_file file to be converted for export
  def initialize(generic_file=nil)
    return unless generic_file
    @generic_file = generic_file

    @record = record_for_export
    @file = filename_and_content_path
    @extras = extra_data
  end

  def to_json(options={})
    options[:except] ||= ["memoized_mesh", "memoized_lcsh", "generic_file"]
    super
  end

  private

  def filename_and_content_path
    {
      "filename": @generic_file.filename,
      "content_path": generic_file_content_path(@generic_file.content.checksum.value)
    }
  end

  def generic_file_content_path(checksum)
    # content paths are generated by taking the first 6 characters of its
    # checksum, and dividing it by 3
    "#{ENV["FEDORA_BINARY_PATH"]}/#{checksum[0..1]}/#{checksum[2..3]}/#{checksum[4..5]}/#{checksum}" unless !checksum
  end

  def extra_data
    data = {}

    if !@generic_file.based_near.empty?
        data["presentation_location"] = @generic_file.based_near
    end
    data["owner"] = owner_info
    data["permissions"] = file_permissions

    data
  end

  def owner_info
    user = User.find_by(username: @generic_file.depositor)

    if user
      {
        "netid": user.username,
        "email": user.email
      }
    else
      {
        "netid": "unknown",
        "email": "unknown"
      }
    end
  end

  def file_permissions
    permission_data = Hash.new { |h,k| h[k] = [] }

    @generic_file.permissions.each do |permission|
      permission_data[permission.access] << permission.agent_name
    end

    permission_data
  end

  def record_for_export
    {
      "pids": invenio_pids(@generic_file.doi.shift),
      "metadata": invenio_metadata,
      "files": {"enabled": true},
      "provenance": invenio_provenance(@generic_file.proxy_depositor, @generic_file.on_behalf_of),
      "access": invenio_access(@generic_file.visibility)
    }
    # @label = generic_file.label
    # @depositor = generic_file.depositor
    # @arkivo_checksum = generic_file.arkivo_checksum
    # @relative_path = generic_file.relative_path
    # @import_url = generic_file.import_url
    # @resource_type = generic_file.resource_type
    # @title = generic_file.title
    # @creator = generic_file.creator
    # @contributor = generic_file.contributor
    # @description = generic_file.description
    # @tag = generic_file.tag
    # @rights = generic_file.rights
    # @publisher = generic_file.publisher
    # @date_created = generic_file.date_created
    # @date_uploaded = generic_file.date_uploaded
    # @date_modified = generic_file.date_modified
    # @subject = generic_file.subject
    # @language = generic_file.language
    # @identifier = generic_file.identifier
    # @based_near = generic_file.based_near
    # @related_url = generic_file.related_url
    # @bibliographic_citation = generic_file.bibliographic_citation
    # @source = generic_file.source
    # @batch_id = generic_file.batch.id if generic_file.batch
    # @visibility = generic_file.visibility
    # @versions = versions(generic_file)
    # @permissions = permissions(generic_file)
  end

  def invenio_pids(doi)
    {
      "doi": {
        "identifier": doi, # doi is stored in an array
        "provider": "datacite",
        "client": "digitalhub"
      }
    }
  end

  def invenio_provenance(proxy_depositor, on_behalf_of)
    {
      "created_by": {
        "user": proxy_depositor
      },
      "on_behalf_of": {
        "user": on_behalf_of
      }
    }
  end

  def invenio_access(file_visibility)
    accessibility = file_visibility == OPEN_ACCESS ? INVENIO_PUBLIC : INVENIO_RESTRICTED

    {
      "record": accessibility,
      "files": accessibility
    }
  end

  def invenio_metadata
    {
      "resource_type": resource_type(@generic_file.resource_type.shift),
      "creators": @generic_file.creator.map{ |creator| build_creator_contributor_json(creator) },
      "title": @generic_file.title.first,
      "additional_titles": additional(category: "title", array: @generic_file.title),
      "description": @generic_file.description.first,
      "additional_descriptions": additional(category: "description", array: @generic_file.description),
      "publisher": @generic_file.publisher.shift,
      "publication_date": format_publication_date(@generic_file.date_created.shift || @generic_file.date_uploaded.to_s),
      "subjects": SUBJECT_SCHEMES.map{ |subject_type| subjects_for_scheme(@generic_file.send(subject_type), subject_type) }.compact.flatten,
      "contributors": contributors(@generic_file.contributor),
      "dates": @generic_file.date_created.map{ |date| {"date": normalize_date(date), "type": {"id": "created"}, "description": "When the item was originally created."} },
      "languages": @generic_file.language.map{ |lang| lang.present? && lang.downcase == ENGLISH ? {"id": "eng"} : nil }.compact,
      "identifiers": ark_identifiers(@generic_file.ark),
      "related_identifiers": related_identifiers(@generic_file.related_url),
      "sizes": Array.new.tap{ |size_json| size_json << "#{@generic_file.page_count} pages" if !@generic_file.page_count.blank? },
      "formats": [@generic_file.mime_type],
      "version": version(@generic_file.content),
      "rights": rights(@generic_file.rights),
      "locations": {"features": @generic_file.subject_geographic.present? ? @generic_file.subject_geographic.map{ |location| {place: location} } : []},
      "funding": funding(@generic_file.id)
    }
  end

  def resource_type(digitalhub_subtype)
    irdm_types = DH_IRDM_RESOURCE_TYPES[digitalhub_subtype]

    if irdm_types
      {
        "id": irdm_types[1]
      }
    else # for resource types with no mappings
      {
        "id": "other-other"
      }
    end
  end

  def build_creator_contributor_json(creator)
    if creator_data = @@person_or_org_data[creator]
      return creator_data
    # Organization
    elsif organization?(creator)
      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["name"] =  creator
            hash["type"] = "organizational"
          end
      }
    # User within DigitalHub
    elsif dh_user = User.find_by(formal_name: creator)
      dh_user_formal_name = dh_user.formal_name.split(',') # split name into components to be reused
      family_name = dh_user_formal_name.shift # remove first value from formal name
      given_name = dh_user_formal_name.join(' ') # the remaining strings becomes given name

      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["type"] = "personal"
            hash["given_name"] = given_name
            hash["family_name"] = family_name
            hash["identifiers"] = {"scheme": "orcid", "identifier": dh_user.orcid.split('/').pop} if dh_user.orcid.present?
          end
      }
    # Personal record without user in database
    elsif creator.include?(",")
      family_name, given_name = creator.split(',')
      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["type"] = "personal"
            hash["given_name"] = given_name.lstrip
            hash["family_name"] = family_name.lstrip
          end
      }
    # Unknown / Not Identified creator
    else
      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["name"] = creator
            hash["type"] = "organizational"
          end
      }
    end

    # this line only runs if there is an update to @@person_or_org_data
    File.write(MEMOIZED_PERSON_OR_ORG_DATA_FILE, @@person_or_org_data)
    # return the actual json
    json
  end # build_creator_contributor_json

  def additional(category:, array:)
    type = set_type(category)
    # return all values except the first
    tail_values = array.slice(1..-1)
    return [] if tail_values.blank?

    # remove the strings that contain only spaces or are empty, then map
    tail_values.delete_if(&:blank?).map do |word|
      {"#{category}": word, "type": {"id": type, "title": {"en": type.titleize}}}
    end
  end

  def set_type(type)
    case type
    when "title"
      "alternative-title"
    when "description"
      "other"
    end
  end

  # return array of invenio formatted subjects
  def subjects_for_scheme(terms, scheme)
    mapped_terms = terms.map do |term|
      pid = @@header_lookup.pid_lookup_by_scheme(term, scheme)

      if pid.present?
        {id: pid}
      elsif scheme == :subject_name || scheme == :tag
        {subject: term}
      end
    end

    mapped_terms.compact
  end

  def contributors(contributors)
    contributors.map do |contributor|
      contributor_json = build_creator_contributor_json(contributor)
      contributor_json.merge!({"role": {id: ROLE_OTHER}})
      contributor_json
    end
  end

  def ark_identifiers(arks)
    arks.map do |ark|
      {
        "identifier": ark,
        "scheme": "ark"
      }
    end
  end

  def rights(license_urls)
    license_urls.map do |license_url|
      license_data = @@license_data[license_url.to_sym]

      if license_url == ALL_RIGHTS_RESERVED
        {
          "id": license_data[:"licenseId"],
          "title": {"en": license_data[:"name"]}
        }
      elsif license_data.present?
        {
          "id": license_data[:"licenseId"],
          "link": license_url,
          "title": {"en": license_data[:"name"]}
        }
      end
    end
  end

  def version(content)
    return "" unless content.has_versions?
    version_number = content.versions.all.length

    "v#{version_number}.0.0"
  end

  def related_identifiers(related_url)
    identifiers = related_url.map do |url|
      next if url.blank?

      if doi_url?(url)
        doi = url.split(DOI_ORG).last

        {
          "identifier": doi,
          "scheme": "doi",
          "relation_type": {"id": "isRelatedTo"}
        }
      else
        {
          "identifier": url,
          "scheme": "url",
          "relation_type": {"id": "isRelatedTo"}
        }
      end
    end

    identifiers.compact
  end

  def doi_url?(url)
    url.include?(DOI_ORG)
  end

  def format_publication_date(publication_date)
    normalize_date(publication_date)
  end

  def normalize_date(date_string)
    split_date = date_string.split(/[-,\/ ]/).map(&:downcase)
    # date format starts with month first
    if (!split_date.blank? && split_date[0].length < 3)
      split_date = rearrange_year(split_date)
    end

    month_names = (split_date & MONTHNAMES)
    abbr_month_names = (split_date & ABBR_MONTHNAMES)

    # blank and unddated
    if date_string.blank? || (split_date & UNDATED).any? || (split_date & SEASONS).any?
      return ""
    # circa date
    elsif (split_date & CIRCA_VALUES).any?
      return date_string.gsub(Regexp.union(CIRCA_VALUES), "").strip
    # date range without month name or month abbreviations
    elsif (split_date.length != 3 && date_string.length == 9)
      return date_string.gsub(" ", "").gsub("-", "/")
    # date range with month name or month abbreviations
    elsif month_names.length > 1 || abbr_month_names.length > 1
      # two months, one year
      if split_date.length == 3
        start_month = MONTHNAMES.index(split_date[0]) || ABBR_MONTHNAMES.index(split_date[0])
        end_month = MONTHNAMES.index(split_date[1]) || ABBR_MONTHNAMES.index(split_date[1])
        year = split_date.last.to_i

        return "#{Date.new(year, start_month).strftime("%Y-%m")}/#{Date.new(year, end_month).strftime("%Y-%m")}"
      # two months, two years
      else
        start_month = MONTHNAMES.index(split_date[0]) || ABBR_MONTHNAMES.index(split_date[0])
        start_year = split_date[1].to_i
        end_month = MONTHNAMES.index(split_date[2]) || ABBR_MONTHNAMES.index(split_date[2])
        end_year = split_date[3].to_i

        return "#{Date.new(start_year, start_month).strftime("%Y-%m")}/#{Date.new(end_year, end_month).strftime("%Y-%m")}"
      end
    # date with month or month abbreviation in it
    elsif month_names.present? || abbr_month_names.present?
      year = split_date.last.to_i
      month = MONTHNAMES.index(split_date[0]) || ABBR_MONTHNAMES.index(split_date[0])
      day = split_date[1].to_i
      day = nil if day == year
    # regular date
    else
      split_date.map!(&:to_i)
      split_date_length = split_date.length

      if split_date_length == 3
        year = split_date[0]
        month = split_date[1]
        day = split_date[2]
      elsif split_date_length == 2
        year = split_date[0]
        month = split_date[1]
      else split_date_length == 1
        year = split_date[0]
      end
    end

    # build the date
    if day && month && year
      Date.new(year, month, day).strftime("%Y-%m-%d")
    elsif month && year
      Date.new(year, month).strftime("%Y-%m")
    elsif year
      Date.new(year).strftime("%Y")
    else
      ""
    end
  end

  def rearrange_year(date_array)
    if date_array[2].length == 2
      # drawing the line at 22 as the year for when we no longer refer to 1900s
      if date_array[2].to_i > 22
        date_array[2] = "19#{date_array[2]}"
      else
        date_array[2] = "20#{date_array[2]}"
      end
    end

    [date_array[2], date_array[0], date_array[1]]
  end

  def funding(file_id)
    @@funding_data[file_id] || [{}]
  end
end
