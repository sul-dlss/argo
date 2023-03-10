# frozen_string_literal: true

require "rails_helper"

RSpec.describe DescriptionsGrouper do
  subject(:run) { described_class.group(descriptions:) }

  let(:descriptions) do
    {
      druid1 => DescriptionExport.export(description: description1, source_id: ""),
      druid2 => DescriptionExport.export(description: description2, source_id: ""),
      druid3 => DescriptionExport.export(description: description3, source_id: "")
    }
  end

  let(:description1) do
    JSON.parse(
      <<~JSON
        {
          "form": [{
            "value": "Portrait",
            "type": "genre",
            "source": {
              "code": "aat",
              "uri": "http://vocab.getty.edu/page/aat/"
            }
          }, {
            "value": "still image",
            "type": "resource type",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "value": "oil on canvas",
            "type": "form"
          }, {
            "value": "manuscript",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "value": "36 x 36 inches",
            "type": "extent"
          }, {
            "value": "reformatted digital",
            "type": "digital origin",
            "source": {
              "value": "MODS digital origin terms"
            }
          }],
          "note": [{
            "value": "This work is represented by a cropped digital scan from an archival 3 1/4 x  5 inch color photograph housed in the artists Paintings I album in the archive of The Martin Wong Foundation c/o P.P.O.W Gallery, New York.",
            "type": "abstract"
          }, {
            "value": "The artist; private collection, Eureka, 1976",
            "type": "ownership",
            "displayLabel": "Provenance"
          }, {
            "value": "Humboldt County, CA",
            "displayLabel": "Place of creation"
          }, {
            "value": "foo bar",
            "type": "ownership",
            "displayLabel": "Provenance"
          }]
        }
      JSON
    )
  end
  let(:description2) do
    JSON.parse(
      <<~JSON
        {
          "form": [{
            "value": "Still life",
            "type": "genre",
            "uri": "http://vocab.getty.edu/aat/300015638",
            "source": {
              "code": "aat",
              "uri": "http://vocab.getty.edu/page/aat/"
            }
          }, {
            "value": "still image",
            "type": "resource type",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "value": "manuscript",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "value": "moving image",
            "type": "resource type",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "value": "ink on paper",
            "type": "form"
          }, {
            "value": "14 x 11 inches",
            "type": "extent"
          }, {
            "value": "reformatted digital",
            "type": "digital origin",
            "source": {
              "value": "MODS digital origin terms"
            }
          }],
          "note": [{
            "value": "The artist; Estate of Martin Wong, 1999; The Martin Wong Foundation (P.P.O.W Gallery, New York), 2017",
            "type": "ownership",
            "displayLabel": "Provenance"
          }]
        }
      JSON
    )
  end
  let(:description3) do
    JSON.parse(
      <<~JSON
        {
          "form": [{
            "value": "still image",
            "type": "resource type",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "value": "acrylic on board",
            "type": "form"
          }, {
            "value": "23 x 23 inches",
            "type": "extent"
          }, {
            "value": "reformatted digital",
            "type": "digital origin",
            "source": {
              "value": "MODS digital origin terms"
            }
          }, {
            "value": "manuscript",
            "source": {
              "value": "MODS resource types"
            }
          }, {
            "note": [{
              "value": "trapezoid"
            }]
          }],
          "note": [{
            "value": "The artist; Estate of Martin Wong, 1999; The Martin Wong Foundation (P.P.O.W Gallery, New York), 2017",
            "type": "ownership",
            "displayLabel": "Provenance"
          }, {
            "value": "{Climbing the East Village} (group exhibition), Hal Bromm, New York, January 7-February 4, 1984; {49th Anniversary Exhibition} (group exhibition), Hal Bromm, New York, October 25-March 31, 2016; {Hong Kong} (group exhibition), MX Gallery, New York, April 6-May 3, 2019",
            "type": "exhibitions",
            "displayLabel": "Exhibition history"
          }, {
            "value": "141 Ridge Street, New York, NY",
            "displayLabel": "Place of creation"
          }]
        }      
      JSON
    )
  end

  let(:druid1) { "druid:bb467kj6050" }
  let(:druid2) { "druid:bb560fk6027" }
  let(:druid3) { "druid:bb976rq0538" }

  it "groups forms as expected" do
    expect(run.dig(druid1, "form1.source.value")).to eq("MODS resource types")
    expect(run.dig(druid1, "form1.type")).to eq("resource type")
    expect(run.dig(druid1, "form1.value")).to eq("still image")
    expect(run.dig(druid1, "form2.type")).to be_nil
    expect(run.dig(druid1, "form2.value")).to be_nil
    expect(run.dig(druid1, "form3.type")).to eq("form")
    expect(run.dig(druid1, "form3.value")).to eq("oil on canvas")
    expect(run.dig(druid1, "form4.type")).to eq("extent")
    expect(run.dig(druid1, "form4.value")).to eq("36 x 36 inches")
    expect(run.dig(druid1, "form5.type")).to eq("digital origin")
    expect(run.dig(druid1, "form5.value")).to eq("reformatted digital")
    expect(run.dig(druid1, "form5.source.value")).to eq("MODS digital origin terms")
    expect(run.dig(druid1, "form6.type")).to eq("genre")
    expect(run.dig(druid1, "form6.value")).to eq("Portrait")
    expect(run.dig(druid1, "form7.value")).to eq("manuscript")
    expect(run.dig(druid1, "form7.source.value")).to eq("MODS resource types")
    expect(run.dig(druid1, "form8.note1.value")).to be_nil

    expect(run.dig(druid2, "form1.source.value")).to eq("MODS resource types")
    expect(run.dig(druid2, "form1.type")).to eq("resource type")
    expect(run.dig(druid2, "form1.value")).to eq("still image")
    expect(run.dig(druid2, "form2.type")).to eq("resource type")
    expect(run.dig(druid2, "form2.value")).to eq("moving image")
    expect(run.dig(druid2, "form3.type")).to eq("form")
    expect(run.dig(druid2, "form3.value")).to eq("ink on paper")
    expect(run.dig(druid2, "form4.type")).to eq("extent")
    expect(run.dig(druid2, "form4.value")).to eq("14 x 11 inches")
    expect(run.dig(druid2, "form5.type")).to eq("digital origin")
    expect(run.dig(druid2, "form5.value")).to eq("reformatted digital")
    expect(run.dig(druid2, "form5.source.value")).to eq("MODS digital origin terms")
    expect(run.dig(druid2, "form6.type")).to eq("genre")
    expect(run.dig(druid2, "form6.value")).to eq("Still life")
    expect(run.dig(druid2, "form7.value")).to eq("manuscript")
    expect(run.dig(druid2, "form7.source.value")).to eq("MODS resource types")
    expect(run.dig(druid2, "form8.note1.value")).to be_nil

    expect(run.dig(druid3, "form1.source.value")).to eq("MODS resource types")
    expect(run.dig(druid3, "form1.type")).to eq("resource type")
    expect(run.dig(druid3, "form1.value")).to eq("still image")
    expect(run.dig(druid3, "form2.type")).to be_nil
    expect(run.dig(druid3, "form2.value")).to be_nil
    expect(run.dig(druid3, "form3.type")).to eq("form")
    expect(run.dig(druid3, "form3.value")).to eq("acrylic on board")
    expect(run.dig(druid3, "form4.type")).to eq("extent")
    expect(run.dig(druid3, "form4.value")).to eq("23 x 23 inches")
    expect(run.dig(druid3, "form5.note1.value")).to be_nil
    expect(run.dig(druid3, "form5.type")).to eq("digital origin")
    expect(run.dig(druid3, "form5.value")).to eq("reformatted digital")
    expect(run.dig(druid3, "form5.source.value")).to eq("MODS digital origin terms")
    expect(run.dig(druid3, "form6.type")).to be_nil
    expect(run.dig(druid3, "form6.value")).to be_nil
    expect(run.dig(druid3, "form7.value")).to eq("manuscript")
    expect(run.dig(druid3, "form7.source.value")).to eq("MODS resource types")
    expect(run.dig(druid3, "form8.note1.value")).to eq("trapezoid")
  end

  it "groups notes as expected" do
    expect(run.dig(druid1, "note1.displayLabel")).to eq("Provenance")
    expect(run.dig(druid1, "note1.type")).to eq("ownership")
    expect(run.dig(druid1, "note2.displayLabel")).to eq("Provenance")
    expect(run.dig(druid1, "note2.type")).to eq("ownership")
    expect(run.dig(druid1, "note3.displayLabel")).to eq("Place of creation")
    expect(run.dig(druid1, "note3.type")).to be_nil
    expect(run.dig(druid1, "note4.displayLabel")).to be_nil
    expect(run.dig(druid1, "note4.type")).to eq("abstract")
    expect(run.dig(druid1, "note5.displayLabel")).to be_nil
    expect(run.dig(druid1, "note5.type")).to be_nil

    expect(run.dig(druid2, "note1.displayLabel")).to eq("Provenance")
    expect(run.dig(druid2, "note1.type")).to eq("ownership")
    expect(run.dig(druid2, "note2.displayLabel")).to be_nil
    expect(run.dig(druid2, "note2.type")).to be_nil
    expect(run.dig(druid2, "note3.displayLabel")).to be_nil
    expect(run.dig(druid2, "note3.type")).to be_nil
    expect(run.dig(druid2, "note4.displayLabel")).to be_nil
    expect(run.dig(druid2, "note4.type")).to be_nil
    expect(run.dig(druid2, "note5.displayLabel")).to be_nil
    expect(run.dig(druid2, "note5.type")).to be_nil

    expect(run.dig(druid3, "note1.displayLabel")).to eq("Provenance")
    expect(run.dig(druid3, "note1.type")).to eq("ownership")
    expect(run.dig(druid2, "note2.displayLabel")).to be_nil
    expect(run.dig(druid2, "note2.type")).to be_nil
    expect(run.dig(druid3, "note3.displayLabel")).to eq("Place of creation")
    expect(run.dig(druid3, "note3.type")).to be_nil
    expect(run.dig(druid3, "note4.displayLabel")).to be_nil
    expect(run.dig(druid3, "note4.type")).to be_nil
    expect(run.dig(druid3, "note5.displayLabel")).to eq("Exhibition history")
    expect(run.dig(druid3, "note5.type")).to eq("exhibitions")
  end

  context "with a more complex example containing multiple repeat values" do
    let(:descriptions) do
      {
        druid1 => DescriptionExport.export(description: description1, source_id: ""),
        druid2 => DescriptionExport.export(description: description2, source_id: ""),
        druid3 => DescriptionExport.export(description: description3, source_id: ""),
        druid4 => DescriptionExport.export(description: description4, source_id: ""),
        druid5 => DescriptionExport.export(description: description5, source_id: ""),
        druid6 => DescriptionExport.export(description: description6, source_id: "")
      }
    end

    let(:description1) do
      JSON.parse(
        <<~JSON
          {          
            "form": [{
              "value": "computer program",
              "type": "genre",
              "source": {
                "code": "rdacontent"
              }
            }, {
              "value": "optical disc",
              "type": "form",
              "source": {
                "code": "marcsmd"
              }
            }, {
              "value": "3 computer discs ; 4 3/4 in.",
              "type": "extent"
            }, {
              "value": "software, multimedia",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "computer disc",
              "type": "carrier",
              "source": {
                "code": "rdacarrier"
              }
            }, {
              "value": "computer",
              "type": "media",
              "source": {
                "code": "rdamedia"
              }
            }, {
              "value": "disc",
              "type": "media"
            }],
            "note": [{
              "value": "Federal Financial Institutions Examination Council.",
              "type": "statement of responsibility"
            }, {
              "value": "Title from disc label."
            }, {
              "value": "Disc characteristics: CD-ROM.",
              "type": "system details"
            }, {
              "value": "note with display label",
              "displayLabel": "Display label"
            }, {
              "value": "note with display label and type",
              "type": "condition",
              "displayLabel": "Another label"
            }, {
              "value": "Another note with display label",
              "displayLabel": "Display label"
            }]
          }
        JSON
      )
    end
    let(:description2) do
      JSON.parse(
        <<~JSON
          {
            "form": [{
              "value": "numeric data",
              "type": "genre",
              "source": {
                "code": "marcgt"
              }
            }, {
              "value": "electronic resource",
              "type": "form",
              "source": {
                "code": "gmd"
              }
            }, {
              "value": "1 CD-ROM ; 4 3/4 in. + 1 users guide (loose-leaf ; 23 cm.)",
              "type": "extent"
            }, {
              "value": "software, multimedia",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "text",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }],
            "note": [{
              "value": "Provides extensive structural information about surface structures determined from experiment.",
              "type": "abstract"
            }, {
              "value": "Title from disc label."
            }, {
              "value": "May 2004."
            }, {
              "value": "Users guide entitled: NIST surface structure database (SSD) with interactive analysis and visualization / authors, P.R. Watson, M.A. Van Hove, K. Herrmann."
            }, {
              "value": "System requirements: Intel Pentium processor",
              "type": "system details"
            }, {
              "value": "note with display label",
              "displayLabel": "Display label"
            }, {
              "value": "note with display label and type",
              "type": "condition",
              "displayLabel": "Another label"
            }]
          }
        JSON
      )
    end
    let(:description3) do
      JSON.parse(
        <<~JSON
          {          
            "form": [{
              "value": "computer dataset",
              "type": "genre",
              "source": {
                "code": "rdacontent"
              }
            }, {
              "value": "optical disc",
              "type": "form",
              "source": {
                "code": "marcsmd"
              }
            }, {
              "value": "1 computer disc : CD-ROM ; 4 3/4 in. + 1 user guide (12 leaves : illustrations ; 28 cm.)",
              "type": "extent"
            }, {
              "value": "software, multimedia",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "text",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "computer disc",
              "type": "carrier",
              "source": {
                "code": "rdacarrier"
              }
            }, {
              "value": "computer",
              "type": "media",
              "source": {
                "code": "rdamedia"
              }
            }],
            "note": [{
              "value": "Converts input addresses to geographical coordinates (latitude-longitude) and then converts those to Census Block codes.The Geocoder with 2012 Estimates and 2017 Projections appends additional demographic variables from the 2012 Estimates and 2017 Projections. It includes a comprehensive set of variables including population counts, age, race, households, income, and housing.",
              "type": "abstract"
            }, {
              "value": "GeoLytics, Inc.",
              "type": "statement of responsibility"
            }, {
              "value": "Title from disc label."
            }, {
              "value": "Accompanying user guide is for an earlier version, Â©2008."
            }, {
              "value": "note with type but not display label",
              "type": "condition"
            }]
          }        
        JSON
      )
    end
    let(:description4) do
      JSON.parse(
        <<~JSON
          {          
            "form": [{
              "value": "Databases",
              "type": "genre",
              "source": {
                "code": "lcgft"
              }
            }, {
              "value": "optical disc",
              "type": "form",
              "source": {
                "code": "marcsmd"
              }
            }, {
              "value": "1 computer disc ; 4 3/4 in. + 1 volume (9 leaves : illustrations ; 28 cm)",
              "type": "extent"
            }, {
              "value": "software, multimedia",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "text",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "computer disc",
              "type": "carrier",
              "source": {
                "code": "rdacarrier"
              }
            }, {
              "value": "computer",
              "type": "media",
              "source": {
                "code": "rdamedia"
              }
            }],
            "note": [{
              "value": "Title from disc surface."
            }, {
              "value": "Accompanying booklet is user guide."
            }, {
              "value": "2016 USPS Zip+4 with 2014 ACS, 2016 estimates and 021 projections."
            }],
            "adminMetadata": {
              "note": [{
                "value": "Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7_SDR_v2-5.xsl (SUL 3.7 version 2.5 20210421; LC Revision 1.140 20200717)",
                "type": "record origin"
              }]
            }
          }        
        JSON
      )
    end
    let(:description5) do
      JSON.parse(
        <<~JSON
          {          
            "form": [{
              "value": "Data sets",
              "type": "genre",
              "source": {
                "code": "lcgft"
              }
            }, {
              "value": "remote",
              "type": "form",
              "source": {
                "code": "marcsmd"
              }
            }, {
              "value": "1 online resource",
              "type": "extent"
            }, {
              "value": "software, multimedia",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }, {
              "value": "online resource",
              "type": "carrier",
              "source": {
                "code": "rdacarrier"
              }
            }, {
              "value": "computer",
              "type": "media",
              "source": {
                "code": "rdamedia"
              }
            }],
            "note": [{
              "value": "40-Year Textual Digital Archive of nytimes.com, initially: 1/1/1980-12/31/2020, which consists of all available articles (approximately 3,000,000) published by The New York Times, including but not limited to news, lifestyle, opinion and The New York Times Magazine, and excludes reader comments, paid obituaries and the kids section. The archives are packed by year, and the naming convention is nyt_nitf_YYYY.tar.gz. Inside the tar archive will be one folder per month, named YYYYMM, and inside of those folders will be individual files for each story moved that year. The naming convention for the stories is YYYY and then an internal ID number. Stories are marked up using News Industry Text Format (NITF 3.3).",
              "type": "abstract"
            }, {
              "value": "Initial file, 1980-2020-",
              "type": "date/sequential designation"
            }, {
              "value": "Description based on online resource, title from email from The New York Times Business Development (Stanford University Libraries, viewed November 2, 2021)"
            }],
            "access": {
              "url": [{
                "value": "https://stanforduniversity.qualtrics.com/jfe/form/SV_8qNB2eNTPjHDDtc",
                "note": [{
                  "value": "Available to Stanford-affiliated users. Data Use Agreement Required for Access"
                }]
              }, {
                "value": "https://code.stanford.edu/sul-cidr/the-new-york-times-archive",
                "note": [{
                  "value": "Available to Stanford-affiliated users. Data documentation"
                }]
              }],
              "note": [{
                "value": "Users must agree to the Data Use Agreement",
                "type": "use and reproduction"
              }]
            },
            "adminMetadata": {            
              "note": [{
                "value": "Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7_SDR_v2-5.xsl (SUL 3.7 version 2.5 20210421; LC Revision 1.140 20200717)",
                "type": "record origin"
              }]
            }
          }        
        JSON
      )
    end
    let(:description6) do
      JSON.parse(
        <<~JSON
          {
            "form": [{
              "value": "numeric data",
              "type": "genre",
              "source": {
                "code": "marcgt"
              }
            }, {
              "value": "electronic",
              "type": "form",
              "source": {
                "code": "marcform"
              }
            }, {
              "value": "6 USB hard drives : 3.5 USB 3.0 to SATA III HDD enclosure with UASP support",
              "type": "extent"
            }, {
              "value": "software, multimedia",
              "type": "resource type",
              "source": {
                "value": "MODS resource types"
              }
            }],
            "note": [{
              "value": "Associated Press Collections includes decades worth of access to an array of internal AP publications and records from select AP bureaus. Contents provided by Associated Press Corporate Archives, AP Images, and AP Archive.",
              "type": "abstract"
            }, {
              "structuredValue": [{
                "value": "1. News features \u0026 internal communications"
              }, {
                "value": "2. U.S. City bureaus collection, 1931-2004"
              }, {
                "value": "3. Washington, D.C. Bureau collection, 1938-2009"
              }, {
                "value": "4. The Middle East bureaus collection, 1967-2008"
              }, {
                "value": "5. European bureaus collection, 1937-2003"
              }, {
                "value": "6. The Washington D.C. Bureau collection, part II (1915-1930)."
              }],
              "type": "table of contents",
              "displayLabel": "Contents"
            }],
            "adminMetadata": {
              "note": [{
                "value": "Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7_SDR_v2-5.xsl (SUL 3.7 version 2.5 20210421; LC Revision 1.140 20200717)",
                "type": "record origin"
              }]
            }
          }        
        JSON
      )
    end

    let(:druid1) { "druid:kg986pw1063" }
    let(:druid2) { "druid:qg486xd2400" }
    let(:druid3) { "druid:sm561bg8999" }
    let(:druid4) { "druid:tr125sy5253" }
    let(:druid5) { "druid:tw155vv5117" }
    let(:druid6) { "druid:vc609bv8108" }

    it "groups forms as expected" do
      expect(run.dig(druid1, "form1.value")).to eq("software, multimedia")
      expect(run.dig(druid1, "form1.type")).to eq("resource type")
      expect(run.dig(druid1, "form2.type")).to be_nil
      expect(run.dig(druid1, "form2.value")).to be_nil
      expect(run.dig(druid1, "form3.value")).to eq("computer program")
      expect(run.dig(druid1, "form3.type")).to eq("genre")
      expect(run.dig(druid1, "form4.value")).to eq("optical disc")
      expect(run.dig(druid1, "form4.type")).to eq("form")
      expect(run.dig(druid1, "form5.value")).to eq("3 computer discs ; 4 3/4 in.")
      expect(run.dig(druid1, "form5.type")).to eq("extent")
      expect(run.dig(druid1, "form6.value")).to eq("computer")
      expect(run.dig(druid1, "form6.type")).to eq("media")
      expect(run.dig(druid1, "form7.value")).to eq("disc")
      expect(run.dig(druid1, "form7.type")).to eq("media")
      expect(run.dig(druid1, "form8.value")).to eq("computer disc")
      expect(run.dig(druid1, "form8.type")).to eq("carrier")

      expect(run.dig(druid2, "form1.value")).to eq("software, multimedia")
      expect(run.dig(druid2, "form1.type")).to eq("resource type")
      expect(run.dig(druid2, "form2.value")).to eq("text")
      expect(run.dig(druid2, "form2.type")).to eq("resource type")
      expect(run.dig(druid2, "form3.value")).to eq("numeric data")
      expect(run.dig(druid2, "form3.type")).to eq("genre")
      expect(run.dig(druid2, "form4.value")).to eq("electronic resource")
      expect(run.dig(druid2, "form4.type")).to eq("form")
      expect(run.dig(druid2, "form5.value")).to eq("1 CD-ROM ; 4 3/4 in. + 1 users guide (loose-leaf ; 23 cm.)")
      expect(run.dig(druid2, "form5.type")).to eq("extent")
      expect(run.dig(druid2, "form6.value")).to be_nil
      expect(run.dig(druid2, "form6.type")).to be_nil
      expect(run.dig(druid2, "form7.value")).to be_nil
      expect(run.dig(druid2, "form7.type")).to be_nil
      expect(run.dig(druid2, "form8.value")).to be_nil
      expect(run.dig(druid2, "form8.type")).to be_nil

      expect(run.dig(druid3, "form1.value")).to eq("software, multimedia")
      expect(run.dig(druid3, "form1.type")).to eq("resource type")
      expect(run.dig(druid3, "form2.value")).to eq("text")
      expect(run.dig(druid3, "form2.type")).to eq("resource type")
      expect(run.dig(druid3, "form3.value")).to eq("computer dataset")
      expect(run.dig(druid3, "form3.type")).to eq("genre")
      expect(run.dig(druid3, "form4.value")).to eq("optical disc")
      expect(run.dig(druid3, "form4.type")).to eq("form")
      expect(run.dig(druid3, "form5.value")).to eq("1 computer disc : CD-ROM ; 4 3/4 in. + 1 user guide (12 leaves : illustrations ; 28 cm.)")
      expect(run.dig(druid3, "form5.type")).to eq("extent")
      expect(run.dig(druid3, "form6.value")).to eq("computer")
      expect(run.dig(druid3, "form6.type")).to eq("media")
      expect(run.dig(druid3, "form7.value")).to be_nil
      expect(run.dig(druid3, "form7.type")).to be_nil
      expect(run.dig(druid3, "form8.value")).to eq("computer disc")
      expect(run.dig(druid3, "form8.type")).to eq("carrier")

      expect(run.dig(druid4, "form1.value")).to eq("software, multimedia")
      expect(run.dig(druid4, "form1.type")).to eq("resource type")
      expect(run.dig(druid4, "form2.value")).to eq("text")
      expect(run.dig(druid4, "form2.type")).to eq("resource type")
      expect(run.dig(druid4, "form3.value")).to eq("Databases")
      expect(run.dig(druid4, "form3.type")).to eq("genre")
      expect(run.dig(druid4, "form4.value")).to eq("optical disc")
      expect(run.dig(druid4, "form4.type")).to eq("form")
      expect(run.dig(druid4, "form5.value")).to eq("1 computer disc ; 4 3/4 in. + 1 volume (9 leaves : illustrations ; 28 cm)")
      expect(run.dig(druid4, "form5.type")).to eq("extent")
      expect(run.dig(druid4, "form6.value")).to eq("computer")
      expect(run.dig(druid4, "form6.type")).to eq("media")
      expect(run.dig(druid4, "form7.value")).to be_nil
      expect(run.dig(druid4, "form7.type")).to be_nil
      expect(run.dig(druid4, "form8.value")).to eq("computer disc")
      expect(run.dig(druid4, "form8.type")).to eq("carrier")

      expect(run.dig(druid5, "form1.value")).to eq("software, multimedia")
      expect(run.dig(druid5, "form1.type")).to eq("resource type")
      expect(run.dig(druid5, "form2.value")).to be_nil
      expect(run.dig(druid5, "form2.type")).to be_nil
      expect(run.dig(druid5, "form3.value")).to eq("Data sets")
      expect(run.dig(druid5, "form3.type")).to eq("genre")
      expect(run.dig(druid5, "form4.value")).to eq("remote")
      expect(run.dig(druid5, "form4.type")).to eq("form")
      expect(run.dig(druid5, "form5.value")).to eq("1 online resource")
      expect(run.dig(druid5, "form5.type")).to eq("extent")
      expect(run.dig(druid5, "form6.value")).to eq("computer")
      expect(run.dig(druid5, "form6.type")).to eq("media")
      expect(run.dig(druid5, "form7.value")).to be_nil
      expect(run.dig(druid5, "form7.type")).to be_nil
      expect(run.dig(druid5, "form8.value")).to eq("online resource")
      expect(run.dig(druid5, "form8.type")).to eq("carrier")

      expect(run.dig(druid6, "form1.value")).to eq("software, multimedia")
      expect(run.dig(druid6, "form1.type")).to eq("resource type")
      expect(run.dig(druid6, "form2.value")).to be_nil
      expect(run.dig(druid6, "form2.type")).to be_nil
      expect(run.dig(druid6, "form3.value")).to eq("numeric data")
      expect(run.dig(druid6, "form3.type")).to eq("genre")
      expect(run.dig(druid6, "form4.value")).to eq("electronic")
      expect(run.dig(druid6, "form4.type")).to eq("form")
      expect(run.dig(druid6, "form5.value")).to eq("6 USB hard drives : 3.5 USB 3.0 to SATA III HDD enclosure with UASP support")
      expect(run.dig(druid6, "form5.type")).to eq("extent")
      expect(run.dig(druid6, "form6.value")).to be_nil
      expect(run.dig(druid6, "form6.type")).to be_nil
      expect(run.dig(druid6, "form7.value")).to be_nil
      expect(run.dig(druid6, "form7.type")).to be_nil
      expect(run.dig(druid6, "form8.value")).to be_nil
      expect(run.dig(druid6, "form8.type")).to be_nil
    end

    it "groups notes as expected" do
      expect(run.dig(druid1, "note1.value")).to eq("Title from disc label.")
      expect(run.dig(druid1, "note2.value")).to be_nil
      expect(run.dig(druid1, "note3.value")).to be_nil
      expect(run.dig(druid1, "note4.value")).to be_nil
      expect(run.dig(druid1, "note5.value")).to eq("note with display label")
      expect(run.dig(druid1, "note5.displayLabel")).to eq("Display label")
      expect(run.dig(druid1, "note6.value")).to eq("Another note with display label")
      expect(run.dig(druid1, "note6.displayLabel")).to eq("Display label")
      expect(run.dig(druid1, "note7.value")).to eq("Federal Financial Institutions Examination Council.")
      expect(run.dig(druid1, "note7.type")).to eq("statement of responsibility")
      expect(run.dig(druid1, "note8.value")).to eq("Disc characteristics: CD-ROM.")
      expect(run.dig(druid1, "note8.type")).to eq("system details")
      expect(run.dig(druid1, "note9.value")).to eq("note with display label and type")
      expect(run.dig(druid1, "note9.type")).to eq("condition")
      expect(run.dig(druid1, "note9.displayLabel")).to eq("Another label")
      expect(run.dig(druid1, "note10.value")).to be_nil
      expect(run.dig(druid1, "note11.value")).to be_nil
      expect(run.dig(druid1, "note12.value")).to be_nil

      expect(run.dig(druid2, "note1.value")).to eq("Title from disc label.")
      expect(run.dig(druid2, "note2.value")).to eq("May 2004.")
      expect(run.dig(druid2, "note3.value")).to eq("Users guide entitled: NIST surface structure database (SSD) with interactive analysis and visualization / authors, P.R. Watson, M.A. Van Hove, K. Herrmann.")
      expect(run.dig(druid2, "note4.value")).to eq("Provides extensive structural information about surface structures determined from experiment.")
      expect(run.dig(druid2, "note4.type")).to eq("abstract")
      expect(run.dig(druid2, "note5.value")).to eq("note with display label")
      expect(run.dig(druid2, "note5.displayLabel")).to eq("Display label")
      expect(run.dig(druid2, "note6.value")).to be_nil
      expect(run.dig(druid2, "note7.value")).to be_nil
      expect(run.dig(druid2, "note8.value")).to eq("System requirements: Intel Pentium processor")
      expect(run.dig(druid2, "note8.type")).to eq("system details")
      expect(run.dig(druid2, "note9.value")).to eq("note with display label and type")
      expect(run.dig(druid2, "note9.type")).to eq("condition")
      expect(run.dig(druid2, "note9.displayLabel")).to eq("Another label")
      expect(run.dig(druid2, "note10.value")).to be_nil
      expect(run.dig(druid2, "note11.value")).to be_nil
      expect(run.dig(druid2, "note12.value")).to be_nil

      expect(run.dig(druid3, "note1.value")).to eq("Title from disc label.")
      expect(run.dig(druid3, "note2.value")).to eq("Accompanying user guide is for an earlier version, Â©2008.")
      expect(run.dig(druid3, "note3.value")).to be_nil
      expect(run.dig(druid3, "note4.value")).to eq("Converts input addresses to geographical coordinates (latitude-longitude) and then converts those to Census Block codes.The Geocoder with 2012 Estimates and 2017 Projections appends additional demographic variables from the 2012 Estimates and 2017 Projections. It includes a comprehensive set of variables including population counts, age, race, households, income, and housing.")
      expect(run.dig(druid3, "note4.type")).to eq("abstract")
      expect(run.dig(druid3, "note5.value")).to be_nil
      expect(run.dig(druid3, "note6.value")).to be_nil
      expect(run.dig(druid3, "note7.value")).to eq("GeoLytics, Inc.")
      expect(run.dig(druid3, "note7.type")).to eq("statement of responsibility")
      expect(run.dig(druid3, "note8.value")).to be_nil
      expect(run.dig(druid3, "note9.value")).to be_nil
      expect(run.dig(druid3, "note10.value")).to eq("note with type but not display label")
      expect(run.dig(druid3, "note10.type")).to eq("condition")
      expect(run.dig(druid3, "note11.value")).to be_nil
      expect(run.dig(druid3, "note12.value")).to be_nil

      expect(run.dig(druid4, "note1.value")).to eq("2016 USPS Zip+4 with 2014 ACS, 2016 estimates and 021 projections.")
      expect(run.dig(druid4, "note2.value")).to be_nil
      expect(run.dig(druid4, "note3.value")).to be_nil
      expect(run.dig(druid4, "note4.value")).to be_nil
      expect(run.dig(druid4, "note5.value")).to be_nil
      expect(run.dig(druid4, "note6.value")).to be_nil
      expect(run.dig(druid4, "note7.value")).to be_nil
      expect(run.dig(druid4, "note8.value")).to be_nil
      expect(run.dig(druid4, "note9.value")).to be_nil
      expect(run.dig(druid4, "note10.value")).to be_nil
      expect(run.dig(druid4, "note11.value")).to be_nil
      expect(run.dig(druid4, "note12.value")).to be_nil

      expect(run.dig(druid5, "note1.value")).to eq("Description based on online resource, title from email from The New York Times Business Development (Stanford University Libraries, viewed November 2, 2021)")
      expect(run.dig(druid5, "note2.value")).to be_nil
      expect(run.dig(druid5, "note3.value")).to be_nil
      expect(run.dig(druid5, "note4.value")).to eq("40-Year Textual Digital Archive of nytimes.com, initially: 1/1/1980-12/31/2020, which consists of all available articles (approximately 3,000,000) published by The New York Times, including but not limited to news, lifestyle, opinion and The New York Times Magazine, and excludes reader comments, paid obituaries and the kids section. The archives are packed by year, and the naming convention is nyt_nitf_YYYY.tar.gz. Inside the tar archive will be one folder per month, named YYYYMM, and inside of those folders will be individual files for each story moved that year. The naming convention for the stories is YYYY and then an internal ID number. Stories are marked up using News Industry Text Format (NITF 3.3).")
      expect(run.dig(druid5, "note4.type")).to eq("abstract")
      expect(run.dig(druid5, "note5.value")).to be_nil
      expect(run.dig(druid5, "note6.value")).to be_nil
      expect(run.dig(druid5, "note7.value")).to be_nil
      expect(run.dig(druid5, "note8.value")).to be_nil
      expect(run.dig(druid5, "note9.value")).to be_nil
      expect(run.dig(druid5, "note10.value")).to be_nil
      expect(run.dig(druid5, "note11.value")).to eq("Initial file, 1980-2020-")
      expect(run.dig(druid5, "note11.type")).to eq("date/sequential designation")
      expect(run.dig(druid5, "note12.value")).to be_nil

      expect(run.dig(druid6, "note1.value")).to be_nil
      expect(run.dig(druid6, "note2.value")).to be_nil
      expect(run.dig(druid6, "note3.value")).to be_nil
      expect(run.dig(druid6, "note4.value")).to eq("Associated Press Collections includes decades worth of access to an array of internal AP publications and records from select AP bureaus. Contents provided by Associated Press Corporate Archives, AP Images, and AP Archive.")
      expect(run.dig(druid6, "note4.type")).to eq("abstract")
      expect(run.dig(druid6, "note5.value")).to be_nil
      expect(run.dig(druid6, "note6.value")).to be_nil
      expect(run.dig(druid6, "note7.value")).to be_nil
      expect(run.dig(druid6, "note8.value")).to be_nil
      expect(run.dig(druid6, "note9.value")).to be_nil
      expect(run.dig(druid6, "note10.value")).to be_nil
      expect(run.dig(druid6, "note11.value")).to be_nil
      expect(run.dig(druid6, "note12.type")).to eq("table of contents")
      expect(run.dig(druid6, "note12.displayLabel")).to eq("Contents")
    end
  end
end
