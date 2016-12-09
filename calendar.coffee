App.widget_data = App.cable.subscriptions.create channel: 'WidgetDataChannel', widget: 'calendar',

  connected: ->
    console.log('calendar connected')

  disconnected: ->
    console.log('calendar disconnected')
    window.calendarWidget.resetTemplate()

  received: (data) ->
    console.log('calendar received data:', data)
    window.calendarWidget.render data



class CalendarWidget
  _this = undefined

  constructor: ->
    _this = this

    this.$widget = $('.widget .calendar')
    this.template = this.$widget[0].innerHTML
    this.resetTemplate()

  resetTemplate: ->
    emptyData = { upcoming_events: [] }
    this.render(emptyData)

  render: (data) ->
    transformedData = this.transformDateAndTime(data)
    renderedTemplate = Mustache.render(this.template, transformedData)
    this.$widget.html(renderedTemplate)

  transformDateAndTime: (data) ->
    transformedData = data
    for datum in data.upcoming_events
      if datum.start_date == datum.end_date
        datum.date = datum.start_date
      else
        datum.date = "#{datum.start_date} - #{datum.end_date}"
    transformedData

$(document).ready ->
  window.calendarWidget = new CalendarWidget()
