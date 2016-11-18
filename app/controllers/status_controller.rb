class StatusController < ApplicationController
  skip_before_action :authenticate_user!

  def log
    if check_recently_indexed
      render status: 200, plain: 'All good! <br/>'
      return
    end
    if params[:test_obj].nil?
      render status: 500, plain: 'Nothing indexed recently.'
      return
    end
    test_item = Dor.find(params[:test_obj])
    test_item.identityMetadata.content_will_change!  # mark as dirty
    test_item.save
    secs = params[:sleep].nil? ? 10.0 : params[:sleep].to_i  # allow override to speed testing
    sleep secs
    if check_recently_indexed
      msg = "All good! <br/>Saved #{params[:test_obj]}"
      render status: 200, plain: msg
    else
      msg = "Nothing indexed recently. Even after saving '#{params[:test_obj]}'."
      render status: 500, plain: msg
    end
  rescue ActiveFedora::ObjectNotFoundError
    msg = "No object '#{params[:test_obj]}' found"
    render status: 404, plain: msg
  end

  protected

  # @return [Boolean]
  def check_recently_indexed
    result = Dor::SearchService.query(
      'indexed_at_dtsi:[NOW-15MINUTES TO NOW]',
      {
        rows: 1,
        fl: 'indexed_at_dtsi'
      }
    )
    docs = result['response']['docs']
    docs.length == 1
  end

end
