// Add status-bar padding for jQueryMobile on iOS7.
;(function(hyper)
{
	function addPaddingForIOS7StatusBar()
	{
		if (hyper.isIOS7())
		{
			//document.write('<div style="width:20px;height:20px;"></div>')
			$('.ui-header').css('margin-top', '20px')
			//$('.ui-content').css('margin-top', '20px')
		}
	}

	$(document).on('pageinit', function(event)
	{
		addPaddingForIOS7StatusBar()
	})
})(window.hyper);
