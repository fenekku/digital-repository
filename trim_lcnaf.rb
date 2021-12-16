File.open("updated_trimmed_lcnaf.yml", "a") do |trimmed_file|
  File.open("lcnaf.skos.ndjson").each_line do |line|
    line_hash = eval(line)

    id = line_hash[:"@context"][:about]
    term = ""

    graph = line_hash[:"@graph"]
    graph.each do |graph_entry|
      if graph_entry[:"@type"] == "skos:Concept"
        # set the skos:prefLabel
        term = graph_entry[:"skos:prefLabel"]
      elsif graph_entry[:"@type"] == "skosxl:Label"
        term = graph_entry[:"skosxl:literalForm"]
      end

      if !term.empty?
        trimmed_file << "\"#{term}\":\"#{id}\"\n"
        break
      end
    end
  end
end
