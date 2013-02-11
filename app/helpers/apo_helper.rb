module ApoHelper
  def creative_commons_options
  [
    ['None',''],
    ['Attribution 3.0 Unported', 'by'],
    ['Attribution Share Alike 3.0 Unported','by_sa'],
    ['Attribution No Derivatives 3.0 Unported', 'by-nd'],
    ['Attribution Non-Commercial 3.0 Unported', 'by-nc'],
    ['Attribution Non-Commercial Share Alike 3.0 Unported', 'by-nc-sa'],
    ['Attribution Non-commercial, No Derivatives 3.0 Unported', 'by-nc-nd']
  ]
  end
  def default_rights_options
    [
      ['World','World'],
      ['Stanford','Stanford'],
      ['Dark (Preserve Only)','Dark'],
      ['None']
    ]
  end
  def options_for_desc_md
    [
      ['MODS'],['TEI']
      ]
  end
  def workflow_options
     q = 'objectType_t:workflow '
      qrys=[]
      result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_t,dc_title_t').docs
      result.sort! do |a,b|
        a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
      end
      result.collect do |doc|
        [Array(doc['dc_title_t']).first,doc['id'].to_s]
      end
  end
  def agreement_options
    q = 'objectType_t:agreement '
      qrys=[]
      result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_t,dc_title_t').docs
      result.sort! do |a,b|
        a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
      end
      result.collect do |doc|
        [Array(doc['dc_title_t']).first,doc['id'].to_s]
      end
  end
end