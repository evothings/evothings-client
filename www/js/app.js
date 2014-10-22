// Application code for the Evothings client.

var app = {}
app.serverList = {}
app.socketId = -1
app.broadcastTimer = null

app.initialize = function()
{

	document.addEventListener('deviceready', app.onDeviceReady, false)

	$('#info_button').bind('click', {articleId: 'info'}, app.showArticle)

	$(function() {
		FastClick.attach(document.body)

		/* Add a clear button to input fields. */
		/*$('input').each(function() {
			var $input_field = $(this)

			$input_field.bind('focus', function() {
				var $clear_button = $('<button class="clear softred">X</button>')
				$(this).after($clear_button)
				$clear_button.bind('click', function () {
					$input_field.val('').focus()
				})
			})

			$input_field.bind('blur', function() {
				var $field = $(this)
				//  Use a delay to make sure that the button isn't removed
				//	before it's clicked.
				setTimeout(function() {
					$field.siblings('button.clear').remove()
				}, 0)
			})
		})*/
	})
}

app.onDeviceReady = function()
{
	// Display the last used ip address.
	app.setSavedIpAddress()

	// Networking API won't work until device is ready.
	// The Scan button is blank initially, and the text
	// of the button is set here, when device is ready.
	// TODO: Would be better to diable the button and
	// enable it when device is ready?
	app.setScanButtonStateToReadyToScan()
}

// Important to always close socket when page reloads/closes!
// Note: beforeunload does not work on iOS!
window.addEventListener('beforeunload', function(e)
{
	app.destroySocketAndTimer()
})

// Set the url field to the saved value.
app.setSavedIpAddress = function()
{
	document.getElementById("hyper-url").value =
		localStorage.getItem('hyper-saved-url')
		|| '192.168.0.x'

}

app.connect = function()
{
	// Get contents of url text field.
	var ip = document.getElementById("hyper-url").value

	// Add protocol and port if needed.
	var url = app.parseIpAddress(ip)

	// Add url to list and connect.
	if (url)
	{
		// Save the URL.
		localStorage.setItem('hyper-saved-url', url)

		// Open URL.
		app.connectTo(url)
	}
	else
	{
		alert('Malformed URL: ' + url)
	}
}

app.scan = function()
{

	if (hyper.isWP())
	{
		// Scan is not available in Windows Phone.
		return
	}

	if (app.broadcastTimer != null) {
		app.destroySocketAndTimer()
		app.setScanButtonStateToNormal()
		return
	}

	function stringToBuffer(string)
	{
		var buffer = new ArrayBuffer(string.length)
		var bufferView = new Uint8Array(buffer);
		for (var i = 0; i < string.length; ++i)
		{
			bufferView[i] = string.charCodeAt(i)
		}
		return buffer
	}

	function bufferToString(buffer)
	{
		var string = ''
		var view = new Uint8Array(buffer)
		for (var i = 0; i < buffer.byteLength; ++i)
		{
			string += String.fromCharCode(view[i])
		}
		return string
	}

	function bind()
	{
		chrome.sockets.udp.bind(
			app.socketId,
			null,
			0,
			function(result)
			{
				// result 0 means success
				if (result == 0)
				{
					// Broadcast UDP packet.
					send()

					// Timer to do continuous broadcast.
					app.broadcastTimer = setInterval(function() { send() }, 2000)

					// Start receiving data.
					chrome.sockets.udp.onReceive.addListener(recv)
				}
				else
				{
					app.setScanButtonStateToError()
					// TODO: When bind fails, try to destroy all sockets.
				}
			}
		)
	}

	function send()
	{
		chrome.sockets.udp.send(
			app.socketId,
			stringToBuffer('hyper.whoIsThere'),
			'255.255.255.255',
			4088,
			function(writeInfo)
			{
				// writeInfo.bytesWritten 16 means success
				// (length of 'hyper.whoIsThere').
				if (writeInfo.bytesWritten != 16)
				{
					// TODO: Error handling?
					app.setScanButtonStateToError()
				}
			}
		)
	}

	function recv(recvInfo)
	{
		try
		{
			// Add server info to list.
			var ip = recvInfo.remoteAddress
			var data = JSON.parse(bufferToString(recvInfo.data))
			data.url = 'http://' + ip + ':' + recvInfo.remotePort
			data.ipAndPort = ip + ':' + recvInfo.remotePort
			app.serverList[ip] = data
			app.displayServers()
		}
		catch (err)
		{
			// TODO: Error handling?
			console.log('EvothingsClient recv error: ' + err)
		}
	}

	// Clear server list.
	app.serverList = {}

	// Clean up existing scan if any.
	app.destroySocketAndTimer()

	// Clear the list of servers.
	$('#hyper-server-list').html('')

	// Set button state.
	app.setScanButtonStateToScanning()

	try {
		// Open UDP connection.
		chrome.sockets.udp.create({}, function(createInfo)
		{
			app.socketId = createInfo.socketId
			bind()
		})
	} catch (err) { 
		app.setScanButtonStateToNormal()
		console.error('Failed to create socket: ' + err)
	}
}

app.destroySocketAndTimer = function()
{
	if (app.broadcastTimer)
	{
		clearInterval(app.broadcastTimer)
		app.broadcastTimer = null
	}

	if (app.socketId > -1)
	{
		chrome.sockets.udp.close(app.socketId)
		app.socketId = -1
	}
}

app.connectTo = function(url)
{
	// Clean up.
	app.destroySocketAndTimer()

	// If the new page has not loaded within this timeout,
	// we consider it an error and display a message.
	setTimeout(function()
		{
			alert('Could not connect to the given address')
			app.setConnectButtonStateToNormal()
		},
		30000)

	// Set button to 'Connecting' state and open the url.
	app.setConnectButtonStateToConnecting()
	window.location.assign(url)
}

// Add protocol and port if needed.
app.parseIpAddress = function(ip)
{
	var url = ip.trim()

	if (!url.match('^https?://[A-Z0-9\.]*.*$'))
	{
		// Add protocol.
		url = 'http://' + url
	}

	if (url.match('^https?://[0-9\.]*$') &&
		!url.match('^https?://[0-9\.]*:[0-9]*$') )
	{
		// Add port to numeric ip address.
		url = url + ':4042'
	}

	return url
}

app.displayServers = function()
{
	var servers = app.serverList

	var list = '' //'<li data-role="list-divider" data-theme="a">EvoThings Studio Servers</li>'

	if (servers.length <= 0)
	{
		list +=
			'<li>'
			+	'<h2>No servers found</h2>'
			+ '</li>'
	}
	else
	{
		for (var key in servers)
		{
			var server = servers[key]
			list +=
				'<li onclick="app.connectTo(\'' +
				server.url + '\')"><a>' +
				'<strong>Touch here to connect to:</strong><br/>' +
				server.name + '<br/>' +
				'<small>' + server.ipAndPort + '</small><br/>' +
				'</a></li>'
		}
	}

	$('#hyper-server-list').html(list)
}

app.setConnectButtonStateToConnecting = function()
{
	$('#hyper-button-connect').html('Connecting')
}

app.setConnectButtonStateToNormal = function()
{
	$('#hyper-button-connect').html('Connect')
}

app.setScanButtonStateToReadyToScan = function()
{
	if (hyper.isWP())
	{
		$('#hyper-button-scan').html('Scan not available')
		$('#hyper-button-scan').css('background', 'rgb(128,128,128)')
		$('#hyper-button-scan').css('border-color', 'rgb(128,128,128)')
		// This does not seem to work.
		$('#hyper-button-scan').button('disable')
	}
	else
	{
		app.setScanButtonStateToNormal()
	}
}

app.setScanButtonStateToNormal = function()
{
	$('#hyper-button-scan').html('SCAN FOR WORKBENCH')
}

app.setScanButtonStateToScanning = function()
{
	$('#hyper-button-scan').html('ABORT SCAN')
}

app.setScanButtonStateToError = function()
{
	$('#hyper-button-scan').html('SCAN FAILED')
}

app.openBrowser = function(url)
{
	window.open(url, '_system', 'location=yes')
}

app.showArticle = function(event)
{
	var articlePage = $('article#' + event.data.articleId)

	$('main').toggle()
	articlePage.toggle()

	if (articlePage.is(":visible"))
		$(this).text('Scan for Workbench')
	else
		$(this).text('Info')
}

app.showMain = function()
{
	$('main').show()
	$('article').hide()
	$('#info_button').text('Info')
	$('header button.back').hide()
}

// Main entry point.
app.initialize()

