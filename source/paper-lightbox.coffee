Polymer
	is: 'paper-lightbox'

	behaviors: [
		Polymer.IronResizableBehavior
	]

	listeners:
		'iron-resize': '_onResize'

	# -----------------
	# --- all get fn
	# -----------------
	_get_typology: ->
		# set vars
		component = this

		# get lightbox typology
		type = component.getAttribute 'type'

		return type

	_get_attribute: (el, attr) ->
		return el.getAttribute(attr)

	_get_class: (el, value) ->
		return el.classList.contains value

	_get_imageRatio: (width, height) ->
		# check image format
		if width > height
			format = 'landscape'
		else
			format = 'portrait'

		return format

	# -----------------
	# --- all set fn
	# -----------------
	_set_typology: ->
		# set vars
		component = this
		type = @_get_typology()

		# check different lightbox typology
		component.listen component.$$('button'), 'tap', '_create_' + type

	_set_bodyFidex: (type)->
		if type != null && type != undefined
			document.body.setAttribute("style", "overflow: hidden;")
		else
			document.body.removeAttribute('style')

	_set_attribute: (el, attr, value) ->
		el.setAttribute attr, value

	_set_class: (el, value) ->
		el.className += ' ' + value

	_set_style: (el, prop, value) ->
		el.style[prop] = value

	_setAjaxRequest: (page)->
		# set vars
		component = this
		xmlhttp = new XMLHttpRequest()

		xmlhttp.onreadystatechange = ->
			if xmlhttp.readyState == 4

				# status ok
				if xmlhttp.status == 200
					# call fn to build main structure
					component._create_popup('', component._create_element('div', 'paper-lightbox-popup_ajaxWrap','', xmlhttp.responseText))

				# status 'not found'
				else if xmlhttp.status == 400
					# call fn to build main structure
					component._create_popup('', component._create_element('div', 'paper-lightbox-popup_ajaxWrap','', 'Page not found'))

				# status 'error'
				else
					# call fn to build main structure
					component._create_popup('', component._create_element('div', 'paper-lightbox-popup_ajaxWrap','', 'Page error'))
			return

		xmlhttp.open("GET", page);
		xmlhttp.send();

		return xmlhttp

	_set_customEvents: ->
		# set vars
		component = this
		events = ['onBeforeLoad', 'onAfterLoad', 'onBeforeClose', 'onAfterClose']

		# create loop to define events
		for event, index in events
			component[index] = undefined

			# create custom event
			if document.createEvent
				component[events[index]] = document.createEvent("HTMLEvents")
				component[events[index]].initEvent(events[index], true, true)
			else
				component.events[index] = document.createEventObject()
				component.events[index].eventType = events[index]

	_set_fireCustomEvents: (customEvent) ->
		# set vars
		component = @

		# fire custom event
		if document.createEvent
			component.dispatchEvent(component[customEvent])
		else
			component.fireEvent("on" + component[customEvent].eventType, component[customEvent])

	# -----------------
	# --- all create fn
	# -----------------
	_create_popup: (type, content) ->
		# fire event before load
		@_set_fireCustomEvents('onBeforeLoad')

		# set vars
		component = this

		# build overlay
		@_create_overlay()

		# set delay
		if @_get_attribute(component, 'openingTime') != null && @_get_attribute(component, 'openingTime') != undefined
			openingTime = @_get_attribute(component, 'openingTime')
		else
			openingTime = 0

		# build container
		container = @_create_element('div', 'paper-lightbox-popup opening')

		# add listener
		@_addListen(container, '_remove')

		# remove class opening
		setTimeout (->
			container.classList.remove('opening')
		), openingTime

		# build close bt
		close = @_create_element('iron-icon', 'paper-lightbox-popup_close', [['icon', 'icons:close']])

		# add listener
		@_addListen(close, '_remove')

		# build window
		component.window = @_create_element('div', 'paper-lightbox-popup_window paper-lightbox-popup_window-' + type)

		# append fn
		component.window.appendChild close
		component.window.appendChild content
		container.appendChild component.window
		component.appendChild container

		# fixed body
		@_set_bodyFidex('fixed')

		# fire event after load
		@_set_fireCustomEvents('onAfterLoad')


	_create_overlay: ->
		# set vars
		component = this

		# create element
		overlay = @_create_element('div', 'paper-lightbox-popup_overlay')
		component.appendChild overlay

		# add listener
		@_addListen(overlay, '_remove')

	_create_element: (tag, style, attr, content) ->
		elem = document.createElement tag
		elem.setAttribute 'class', style

		# set attribute
		if attr != null && attr != undefined
			for arr, index in attr
				elem.setAttribute attr[index][0], attr[index][1]

		# set innerHTML
		if content != null && content != undefined
			elem.innerHTML = content

		return elem

	# 1. ajax
	_create_ajax: ->
		# set vars
		content = this
		url = @_get_attribute(content, 'src')

		@_setAjaxRequest(url)

	# 2. image
	_create_image: ->
		# set vars
		component = this
		image = new Image()

		# create image
		image.onload = ->
			# get image format
			format = component._get_imageRatio(image.naturalWidth, image.naturalHeight)

			# call fn to build main structure
			component._create_popup('image' + ' ' + format, image)

			# fire resize event
			component._onResize()

		image.src = @_get_attribute(component, 'src')

	# 3. inline
	_create_inline: ->
		# set vars
		component = this

		# get content to clone
		inLineContent = document.querySelector @_get_attribute(component, 'src')

		# set cloned el
		content = inLineContent.cloneNode true

		# call fn to build main structure
		@_create_popup('inline', content)


	# 4. iframe
	_create_iframe: ->
		# set vars
		component = this
		path = @_get_attribute(component, 'src')
		repPath = path.replace('/watch?v=', '/embed/')

		# build iframe
		iframe = @_create_element('iframe', '', [['frameborder', '0'],['allowfullscreen', '']])

		# build iframe wrap
		content = @_create_element('div', 'paper-lightbox_iframeWrapper')

		# check path typology
		if path.indexOf('youtube.com/watch?v=') > -1
			@_set_attribute(iframe, 'src', repPath + '?autoplay=1')
		else
			@_set_attribute(iframe, 'src', path + '?autoplay=1')

		# append fn
		content.appendChild iframe

		# call fn to build main structure
		component._create_popup('iframe', content)


	# -----------------
	# --- all action fn
	# -----------------
	_addListen: (el, fn) ->
		# set vars
		component = this

		# add overlay listener
		component.listen el, 'tap', fn

	_remove: (e) ->
		# fire event before close
		@_set_fireCustomEvents('onBeforeClose')

		# set vars
		component = this
		@window = undefined
		popup = component.querySelector('.paper-lightbox-popup')
		overlay = component.querySelector('.paper-lightbox-popup_overlay')
		wrap = component.querySelector('.paper-lightbox-popup')
		close = component.querySelector('.paper-lightbox-popup_close')

		# set delay
		if @_get_attribute(component, 'closingTime') != null && @_get_attribute(component, 'closingTime') != undefined
			closingTime = @_get_attribute(component, 'closingTime')
		else
			closingTime = 0

		# add class 'closing'
		@_set_class(popup, 'closing')

		# set clicked target
		target = e.target

		# remove popup with delay
		setTimeout (->
			# check if target is == wrap or == close
			if target == wrap || target == close
				popup.remove()
				overlay.remove()

				# fire event before close
				component._set_fireCustomEvents('onAfterClose')

		), closingTime

		# remove fixed body
		@_set_bodyFidex()

	# -----------------
	# --- all event fn
	# -----------------
	attached: ->

	_onLoad: ->
		# define typology
		@_set_typology()

	ready: ->
		# set vars
		component = this

		@async(->
			setTimeout (->
				component._onLoad()
				component._set_customEvents()
			), 0
		)

	_onResize: ->
		# if popup is open
		if @window

			# if image has portrait ratio
			if @_get_class(@window, 'portrait')
				# set vars
				image = @window.querySelector('img')

				# set max height
				@_set_style(image, 'maxHeight', (window.innerHeight * 0.8) + 'px')

	open: ->
		fn = '_create_' + @_get_typology()
		@[fn]()
