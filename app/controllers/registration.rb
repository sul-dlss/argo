require 'prawn'
require 'prawn/measurement_extensions'
require 'barby'
require 'barby/outputter/prawn_outputter'

RubyDorServices.controllers :registration do

  get :bulk do
    render 'registration/bulk'
  end

  get :tracksheet, :provides => [:pdf] do
    druids = Array(params[:druid])
    name = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = generate_tracking_pdf(druids)
    pdf.render
  end
  
end