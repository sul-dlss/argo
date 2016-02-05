##
# A GenericJob used as a super class for Argo Bulk Jobs
class GenericJob < ActiveJob::Base
  def perform(_a, _b, _c)
  end
end
