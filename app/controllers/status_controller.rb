class StatusController < ApplicationController
  include ActionView::Helpers::DateHelper
  skip_before_action :authorize!

  def log
    if check_recently_indexed
      render :status => 200, :text => 'All good! <br/>'
      return
    end
    if params[:test_obj].nil?
      render :status => 500, :text => 'Nothing indexed recently.'
      return
    end
    test_item = Dor::Item.find(params[:test_obj])
    test_item.identityMetadata.content_will_change!  # mark as dirty
    test_item.save
    secs = params[:sleep].nil? ? 10.0 : params[:sleep].to_i  # allow override to speed testing
    sleep secs
    if check_recently_indexed
      render :status => 200, :text => "All good! <br/>Saved #{params[:test_obj]}"
      return
    else
      render :status => 500, :text => "Nothing indexed recently. Even after saving '#{params[:test_obj]}'."
      return
    end
  rescue ActiveFedora::ObjectNotFoundError
    render :status => 404, :text => "No object '#{params[:test_obj]}' found"
  end

  protected

  # @return [Boolean]
  def check_recently_indexed
    docs = Dor::SearchService.query('indexed_at_dtsi:[NOW-15MINUTES TO NOW]', {:rows => 1, :fl => 'indexed_at_dtsi'})['response']['docs']
    docs.length == 1
  end

end
