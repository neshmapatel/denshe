xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
           "xmlns:image" => "http://www.google.com/schemas/sitemap-image/1.1" do
  @entries.each do |entry|
    xml.url do
      xml.loc entry[:loc]
      xml.lastmod entry[:lastmod].xmlschema if entry[:lastmod]
      xml.changefreq entry[:changefreq]
      xml.priority entry[:priority]
      if entry[:images].present?
        entry[:images].each do |img|
          xml.tag!("image:image") do
            xml.tag!("image:loc", img[:loc])
            xml.tag!("image:title", img[:title]) if img[:title].present?
            xml.tag!("image:caption", img[:caption]) if img[:caption].present?
          end
        end
      end
    end
  end
end
