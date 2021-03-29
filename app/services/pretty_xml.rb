# frozen_string_literal: true

# Display XML with aesthetically pleasing indenting
class PrettyXml
  PRETTIFY_XSLT = Nokogiri::XSLT <<-XSLT
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output omit-xml-declaration="yes" indent="yes"/>
      <xsl:template match="node()|@*">
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
      </xsl:template>
    </xsl:stylesheet>
  XSLT

  def self.print(xml)
    ng_xml = Nokogiri::XML(xml)
    PRETTIFY_XSLT.transform(ng_xml).to_xml
  end
end
