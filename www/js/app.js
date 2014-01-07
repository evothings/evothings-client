// Application code for the EvoThings client.

var app = {}
app.serverList = []
app.socketId = -1

app.initialize = function()
{
    app.bindEvents()
}

// Bind Event Listeners
//
// Bind any events that are required on startup. Common events are:
// 'load', 'deviceready', 'offline', and 'online'.
app.bindEvents = function()
{
    document.addEventListener('deviceready', app.onDeviceReady, false)
}

app.onDeviceReady = function()
{
	// Networking API won't work until device is ready.
	// The Scan button is blank initially, and the text
	// of the button is set here, when device is ready.
	// TODO: Would be better to diable the button and
	// enable it when device is ready.
	app.setScanButtonStateToReadyToScan()
}

// Important to always close socket when page reloads/closes!
window.addEventListener('beforeunload', function(e)
{
	if (app.socketId > -1)
	{
		chrome.socket.destroy(app.socketId)
	}
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

    // Save the field contents.
    localStorage.setItem('hyper-saved-url', ip)

    // Add protocol and port if needed.
    var url = app.parseIpAddress(ip)

    // Add url to list and connect.
    if (url)
    {
    	app.connectTo(url)
    }
    else
    {
    	alert('Malformed URL: ' + url)
    }
}

app.scan = function()
{
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
			'',
			0,
			function(result)
			{
				// TODO: Error handling?
				// result 0 == success
				if (result == 0)
				{
					send()
				}
				else
				{
					app.setScanButtonStateToNormal()
					// TODO: When bind fails, try to destroy all sockets
					// and scan again. However limit the number of attempts.
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
				// TODO: Error handling?
				// writeInfo.bytesWritten == 16 bytes
				// ('hyper.whoIsThere') means success.
				if (writeInfo.bytesWritten > 0)
				{
					recv()
				}
				else
				{
					app.setScanButtonStateToNormal()
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
						app.serverList.push(data)
						app.displayServers()
						// Call recv again to get data from other servers if any.
						recv()
					}
					catch (err)
					{
						// TODO: Error handling?
						console.log('EvoThingsClient recv error: ' + err)
					}
				}
				// TODO: Keep scanning state on button in case multiple
				// servers will respond?
				// This could be implemented with a timer, but just
				// reset the button to normal for now.
				app.setScanButtonStateToNormal()
			}
		)
	}

	// Clear server list.
	app.serverList = []

	// Set button state.
	app.setScanButtonStateToScanning()

	// Unbind socket in case scan is called multiple times.
	// Important to do this to free up the port before
	// binding the new socket.
	if (app.socketId > -1)
	{
		chrome.socket.destroy(app.socketId)
	}

	// Open UDP connection.
	chrome.socket.create('udp', {}, function(createInfo)
	{
		app.socketId = createInfo.socketId
		bind()
	})
}

app.connectTo = function(url)
{
	// Perhaps not needed anymore since we handle
	// the 'beforeunload' event?
	chrome.socket.destroy(app.socketId)
	app.socketId = -1

	// If the new page has not loaded within this timeout,
	// we consider it an error and display a message.
	setTimeout(function()
		{
			alert('Could not connect to the given address')
			app.setConnectButtonStateToNormal()
		},
		5000)

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
		for (var i = 0; i < servers.length; ++i)
		{
			var server = servers[i]
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
	$('#hyper-button-connect .ui-btn-text').html('Connecting...')
}

app.setConnectButtonStateToNormal = function()
{
	$('#hyper-button-connect .ui-btn-text').html('Connect')
}

app.setScanButtonStateToScanning = function()
{
	$('#hyper-button-scan .ui-btn-text').html('Scanning...')
}

app.setScanButtonStateToReadyToScan = function()
{
	$('#hyper-button-scan .ui-btn-text').html('Scan to connect')
}

app.setScanButtonStateToNormal = function()
{
	$('#hyper-button-scan .ui-btn-text').html('Scan again')
}

app.openBrowser = function(url)
{
	window.open(url, '_blank', 'location=yes')
}

// Display the last used ip address.
app.setSavedIpAddress()

app.initialize()
