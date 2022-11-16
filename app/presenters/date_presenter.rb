# frozen_string_literal: true

class DatePresenter
  def self.render(datetime)
    return "" if datetime.nil? || datetime == ""

    # this needs to use the timezone set in config.time_zone
    begin
      zone = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
      d = datetime.is_a?(Time) ? datetime : DateTime.parse(datetime).in_time_zone(zone)
      I18n.l(d)
    rescue
      d = datetime.is_a?(Time) ? datetime : Time.zone.parse(datetime.to_s)
      d.strftime("%Y-%m-%d %I:%M%p")
    end
  end
end
