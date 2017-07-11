GENDER = {
  "Male": "fa-mars"
  "Female": "fa-venus"
}

collide = (input_dot, dots) ->
  input_dot_y = input_dot.attributes.cy.ownerElement.cy.baseVal.value
  input_dot_x = input_dot.attributes.cx.ownerElement.cx.baseVal.value
  input_dot_r = input_dot.attributes.r.ownerElement.r.baseVal.value

  for dot in dots
    if dot == input_dot
      return false

    x = Math.abs(dot.attributes.cy.ownerElement.cy.baseVal.value - input_dot_y)
    y = Math.abs(dot.attributes.cy.ownerElement.cx.baseVal.value - input_dot_x)

    distance = Math.sqrt(x * x + y * y)
    radius = Math.abs(dot.attributes.r.ownerElement.r.baseVal.value + input_dot_r)
    if distance < radius / 1.6
      return true
  return false

format_age = (age) ->
  years = Math.floor(age)
  days = Math.floor((age - years) * 365)
  return "#{years} years #{days} days"

d3.queue()
  .defer d3.csv, "data/data.csv"
  .defer d3.csv, "data/flags.csv"
  .await (error, data, flags) ->
  FLAGS = {}
  for flag in flags
    FLAGS[flag.code] = flag.flag_url

  events = Array.from new Set data.map (item) ->
    item.event

  # drawing chart
  chart = c3.generate
    data:
      json: data,
      keys:
        x: 'event'
        value: ['age']
      type: 'scatter'
      types:
        data1: 'bar'
      xSort: false
    axis:
      rotated: true,
      x:
        show: true
        type: 'category'
        categories: events
        tick:
          multiline: false
      y:
        min: 18,
        max: 48
    size:
      height: 800
    grid:
      x:
        show: true
      y:
        show: true
    legend:
      show: false
    tooltip:
      sorted: false
      grouped: false
      contents: (d) ->
        $$ = this

        text = "<table class='#{$$.CLASS.tooltip}'><tr><th colspan='2'>#{d[0].data.name}</th></tr>"
        text += "<tr><td class='value'>Event</td><td class='name'>#{d[0].data.event}</td></tr>"
        text += "<tr><td class='value'>Olympic</td><td class='name'>#{d[0].data.olympic}</td></tr>"
        text += "<tr><td class='value'>Place</td><td class='name'><i class='fa fa-circle place-#{d[0].data.place}' aria-hidden='true'></i> #{d[0].data.place}</td></tr>"
        text += "<tr><td class='value'>Age</td><td class='name'>#{format_age(parseFloat(d[0].data.age))}</td></tr>"
        text += "<tr><td class='value'>Gender</td><td class='name'><i class='fa #{GENDER[d[0].data.gender]}' aria-hidden=''true'></i> #{d[0].data.gender}</td></tr>"
        text += "<tr><td class='value'>Country</td><td class='name'>"
        if d[0].data.country of FLAGS
          text += "<img class='flag' src='#{FLAGS[d[0].data.country]}' /> "
        text += "#{d[0].data.country}</td></tr>"
        text += "<table>"

        return text
    oninit: ->
      for value, index in this.data.targets[0].values
        value.data = this.config.data_json[index]
    onrendered: ->
      me = this
      circles = d3.selectAll(".c3-chart-lines > .c3-chart-line > .c3-circles > circle")
      events = {}
      for circle in circles[0]
        if circle.attributes.cy.nodeValue not of events
          events[circle.attributes.cy.nodeValue] = new Array()
        events[circle.attributes.cy.nodeValue].push circle

      i = 0

      div = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0)

      medianHeight = parseInt(d3.selectAll(".c3-xgrids > .c3-xgrid")[0][1].attributes.y1.nodeValue) - parseInt(d3.selectAll(".c3-xgrids > .c3-xgrid")[0][0].attributes.y1.nodeValue) - 5
      for key, value of events
        median = d3.median value, (v) -> v.__data__.value

        g = d3.select("#chart > svg > g:nth-child(2) > g.c3-chart > g.c3-event-rects.c3-event-rects-multiple")
          .append("g")
          .attr
            transform: -> "translate(#{me.api.internal.y(median)},#{parseInt(d3.selectAll(".c3-xgrids > .c3-xgrid")[0][i].attributes.y1.nodeValue)})"
            class: 'median'

        g.append("line")
          .attr
            y1: 5
            y2: medianHeight
            'z-index': -1
          .on "mouseover", ->
          this.style.opacity = .8
          this.parentNode.lastChild.style.fillOpacity = .8
          .on "mouseout", ->
          this.style.opacity = null
          this.parentNode.lastChild.style.fillOpacity = null

        g.append("text")
          .attr
            dx: 5
            dy: 10
            'z-index': -1
          .text "Median: #{format_age(median)}"

        i++

        for dot in value
          step = 0
          start_y_value = dot.attributes.cy.ownerElement.cy.baseVal.value

          while collide(dot, value)
            s = Math.pow(-1, step) * Math.ceil(step / 2)
            dot.setAttribute("cy", start_y_value + s)
            step += 1

