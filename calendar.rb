class Calendar
  require 'nokogiri'
  require 'icalendar'
  require 'awesome_print'

  def initialize
    @cli_mode = false
    @uris = []
    @user = ''
    @password = ''
    @max_events = 0
    @date_time_format = ''
  end

  def start_with_configuration(config)
    @uris = config['uris']
    @user = config['user']
    @password = config['password']
    @max_events = config['upcoming_events']
    @time_format = config['time_format']
    @date_format = config['date_format']

    $widget_scheduler.every '1m', first_in: '3s' do
      events = find_upcoming_events
      WidgetDatum.new(name: 'calendar', data: { upcoming_events: events }).save
    end unless @cli_mode
    ap find_upcoming_events if @cli_mode
  end

  def find_upcoming_events
    events_of_all_calendars = []

    @uris['ical'].each do |uri|
      curl_request = `curl -u "#{@user}":"#{@password}" #{uri}`
      events_of_all_calendars << curl_request
    end if @uris['ical'].present?

    @uris['caldav'].each do |uri|
      curl_request = `curl -X PROPFIND -u "#{@user}":"#{@password}" -H "Content-Type: text/xml" -H "Depth: 1" --data "<propfind xmlns='DAV:'><prop><calendar-data xmlns='urn:ietf:params:xml:ns:caldav'/></prop></propfind>" #{uri}`

      xml_document = Nokogiri::XML(curl_request)
      xml_document.remove_namespaces!
      events_of_one_calendar = xml_document.xpath('//calendar-data').map { |event| event.content }
      events_of_one_calendar = events_of_one_calendar.reject { |element| element.empty? }
      events_of_all_calendars << events_of_one_calendar
    end if @uris['caldav'].present?

    filter_events(events_of_all_calendars.flatten)
  end

  def filter_events(raw_events)
    relevant_events = []
    raw_events.each do |events|
      parsed_events = Icalendar::Event.parse(events)
      next unless parsed_events

      parsed_events.each do |parsed_event|
        start_at = DateTime.parse(parsed_event.dtstart.to_s)
        end_at = DateTime.parse(parsed_event.dtend.to_s)
        if end_at > DateTime.now
          relevant_events << {
            start_at: start_at,
            start_time: create_time(start_at),
            start_date: start_at.strftime(@date_format),
            end_at: end_at,
            end_time: create_time(end_at),
            end_date: end_at.strftime(@date_format),
            name: parsed_event.summary
          }
        end
      end
    end

    sorted_events = relevant_events.sort_by { |k| k[:end_at] }
    return sorted_events[0..(@max_events - 1)] if sorted_events.count > @max_events
    return sorted_events
  end

  def create_time(time)
    return nil if time.strftime('%H%M') == '0000'
    time.strftime(@time_format)
  end

  def cli_mode
    @cli_mode = true
  end
end

calendar = Calendar.new

if __FILE__ == $0
  calendar.cli_mode
  $config = {}
  $config['calendar'] = {}
  $config['calendar']['uris'] = {}
  $config['calendar']['uris']['ical'] = [
    'https://calendar.google.com/calendar/ical/CALENDAR_ID/basic.ics'
  ]
  $config['calendar']['uris']['caldav'] = [
    'https://nextcloud.example.de/remote.php/dav/calendars/USER/CALENDAR/'
  ]
  $config['calendar']['user'] = 'username'
  $config['calendar']['password'] = 'password'
  $config['calendar']['upcoming_events'] = 5
  $config['calendar']['time_format'] = '%H:%M'
  $config['calendar']['date_format'] = '%d.%m'
end

calendar.start_with_configuration $config['calendar']
