App.widget_data = App.cable.subscriptions.create channel: 'WidgetDataChannel', widget: 'calendar',

  connected: ->
    console.log('calendar connected')

  disconnected: ->
    console.log('calendar disconnected')
    # window.calendarWidget.resetTemplate()

  received: (data) ->
    console.log('calendar received data:', data)
    window.calendarWidget.render data



class CalendarWidget
  _this = undefined

  constructor: ->
    _this = this

    this.$widget = $('.widget .calendar')
    this.template = $widget[0].innerHTML

  render: (data) ->
    renderedTemplate = Mustache.render(this.template, data)
    this.$widget.html(renderedTemplate)

$(document).ready ->
  window.calendarWidget = new CalendarWidget()
