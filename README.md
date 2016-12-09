# Calendar Widget

![](calendar.png)

## config options:

- multiple CalDAV URIs (the widget currently understands only specific calendar URIs, not URIs to whole CalDAV accounts)
- a username to access all the CalDAV URIs
- a password to access all the CalDAV URIs
- number of upcoming events the widget should display

## Dependencies

Currently there is no way to tell the Armaturenbrett that a widget has some dependencies. So to install this widget, you have to add the following to the Armaturenbrett's `Gemfile`:

```
gem 'nokogiri'
gem 'icalendar'
```

## CLI usage

The `calendar.rb` can be called via the command line with

```
ruby calendar.rb PASSWORD
```