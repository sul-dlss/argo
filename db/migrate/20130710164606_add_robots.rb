class AddRobots < ActiveRecord::Migration
  def change
    accession_steps = ['content-metadata', 'provenance-metadata', 'remediate-object', 'technical-metadata', 'shelve', 'publish', 'rights-metadata', 'descriptive-metadata', 'sdr-ingest-transfer', 'end-accession']
    accession_steps.each do |step|
      bot = Robot.new(:wf => 'accessionWF', :process => step)
      bot.save
    end
    assembly_steps = ['jp2-create', 'checksum-compute', 'exif-collect', 'accessioning-initiate']
    assembly_steps.each do |step|
      bot = Robot.new(:wf => 'assemblyWF', :process => step)
      bot.save
    end
  end
end
