require 'prawn'
require 'prawn/measurement_extensions'
require 'barby'
require 'barby/outputter/prawn_outputter'

RubyDorServices.controllers :registration do

  get :bulk do
    render 'registration/bulk'
  end

  get :tracksheet, :provides => [:pdf] do
    pdf = Prawn::Document.new(:page_size => [5.5.in, 8.5.in])
    druids = Array(params[:druid])
    druids.each_with_index do |druid,i|
      generate_tracking_sheet(druid, pdf)
      pdf.start_new_page unless (i+1 == druids.length)
    end
    response['content-disposition'] = "attachment; filename=tracksheet.pdf"
    pdf.render
  end
  
end