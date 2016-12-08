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
  end

  def start_with_configuration(config)
    @uris = config['uris']
    @user = config['user']
    @password = config['password']
    @max_events = config['upcoming_events']

    $widget_scheduler.every '1m', first_in: '3s' do
      events = find_upcoming_events
      WidgetDatum.new(name: 'calendar', data: events).save
    end unless @cli_mode
    ap find_upcoming_events if @cli_mode
  end

  def find_upcoming_events
    events_of_all_calendars = []
    @uris.each do |uri|
      curl_request = `curl -X PROPFIND -u #{@user}:#{@password} -H "Content-Type: text/xml" -H "Depth: 1" --data "<propfind xmlns='DAV:'><prop><calendar-data xmlns='urn:ietf:params:xml:ns:caldav'/></prop></propfind>" #{uri}`

      xml_document = Nokogiri::XML(curl_request)
      events_of_one_calendar = xml_document.xpath('//cal:calendar-data').map { |event| event.content }
      events_of_one_calendar = events_of_one_calendar.reject { |element| element.empty? }
      events_of_all_calendars += events_of_one_calendar
    end

    filter_events(events_of_all_calendars)
  end

  def filter_events(raw_events)
    relevant_events = []
    raw_events.each do |event|
      parsed_event = Icalendar::Event.parse(event)[0]

      start_at = DateTime.parse(parsed_event.dtstart.to_s)
      end_at = DateTime.parse(parsed_event.dtend.to_s)
      if end_at > DateTime.now
        relevant_events << {
          start_at: start_at,
          end_at: end_at,
          name: parsed_event.summary
        }
      end
    end

    sorted_events = relevant_events.sort_by { |k| k[:end_at] }
    return sorted_events[0..(@max_events - 1)] if sorted_events.count > @max_events
    return sorted_events
  end

  def cli_mode
    @cli_mode = true
  end
end

calendar = Calendar.new

if __FILE__ == $0
  exit unless ARGV.count == 1
  calendar.cli_mode
  $config = {}
  $config['calendar'] = {}
  $config['calendar']['uris'] = [
    'https://cloud.robert-greinacher.de/remote.php/dav/calendars/testuser/default/'
  ]
  $config['calendar']['user'] = 'testuser'
  $config['calendar']['password'] = ARGV[0]
  $config['calendar']['upcoming_events'] = 5
end

calendar.start_with_configuration $config['calendar']
