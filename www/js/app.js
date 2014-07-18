// Application code for the Evothings client.

var app = {}
app.serverList = {}
app.socketId = -1
app.broadcastTimer = null

app.initialize = function()
{
	document.addEventListener('deviceready', app.onDeviceReady, false)
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
		chrome.socket.bind(
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
					recv()
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
		chrome.socket.sendTo(
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

	function recv()
	{
		chrome.socket.recvFrom(
			app.socketId,
			function(recvInfo)
			{
				if (recvInfo.resultCode > 0)
				{
					try
					{
						// Add server info to list.
						var ip = recvInfo.address
						var data = JSON.parse(bufferToString(recvInfo.data))
						data.url = 'http://' + ip + ':' + data.port
						data.ipAndPort = ip + ':' + data.port
						app.serverList[ip] = data
						app.displayServers()

						// Call recv again to get more data.
						recv()
					}
					catch (err)
					{
						// TODO: Error handling?
						console.log('EvothingsClient recv error: ' + err)
					}
				}
			}
		)
	}

	// Clear server list.
	app.serverList = {}

	// Clean up existing scan if any.
	app.destroySocketAndTimer()

	// Set button state.
	app.setScanButtonStateToScanning()

	// Open UDP connection.
	chrome.socket.create('udp', {}, function(createInfo)
	{
		app.socketId = createInfo.socketId
		bind()
	})
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
		chrome.socket.destroy(app.socketId)
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
				'<li><a onclick="app.connectTo(\'' +
				server.url + '\')">' +
				'<strong>Touch here to connect to:</strong><br/>' +
				server.name + '<br/>' +
				'<small>' + server.ipAndPort + '</small><br/>' +
				'</a></li>'
		}
	}

	$('#hyper-server-list').html(list)
	$('#hyper-server-list').listview('refresh')
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

// Main entry point.
app.initialize()

