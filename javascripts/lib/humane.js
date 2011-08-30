/*
 * Javascript Humane Dates
 * Copyright (c) 2008 Dean Landolt (deanlandolt.com)
 * Re-write by Zach Leatherman (zachleat.com)
 * 
 * Adopted from the John Resig's pretty.js
 * at http://ejohn.org/blog/javascript-pretty-date
 * and henrah's proposed modification 
 * at http://ejohn.org/blog/javascript-pretty-date/#comment-297458
 * 
 * Licensed under the MIT license.
 */

function humane_date(date_str){
	var time_formats = [
		[60, 'Just Now'],
		[90, '1 minute'], // 60*1.5
		[3600, 'minutes', 60], // 60*60, 60
		[5400, '1 hour'], // 60*60*1.5
		[86400, 'hours', 3600], // 60*60*24, 60*60
		[129600, '1 day'], // 60*60*24*1.5
		[604800, 'days', 86400], // 60*60*24*7, 60*60*24
		[907200, '1 week'], // 60*60*24*7*1.5
		[2628000, 'weeks', 604800], // 60*60*24*(365/12), 60*60*24*7
		[3942000, '1 month'], // 60*60*24*(365/12)*1.5
		[31536000, 'months', 2628000], // 60*60*24*365, 60*60*24*(365/12)
		[47304000, '1 year'], // 60*60*24*365*1.5
		[3153600000, 'years', 31536000], // 60*60*24*365*100, 60*60*24*365
		[4730400000, '1 century'], // 60*60*24*365*100*1.5
	];

	var time = ('' + date_str).replace(/-/g,"/").replace(/[TZ]/g," "),
		dt = new Date,
		seconds = ((dt - new Date(time) + (dt.getTimezoneOffset() * 60000)) / 1000),
		token = ' ago',
		i = 0,
		format;

	if (seconds < 0) {
		seconds = Math.abs(seconds);
		token = '';
	}

	while (format = time_formats[i++]) {
		if (seconds < format[0]) {
			if (format.length == 2) {
				return format[1] + (i > 1 ? token : ''); // Conditional so we don't return Just Now Ago
			} else {
				return Math.round(seconds / format[2]) + ' ' + format[1] + (i > 1 ? token : '');
			}
		}
	}

	// overflow for centuries
	if(seconds > 4730400000)
		return Math.round(seconds / 4730400000) + ' centuries' + token;

	return date_str;
};

if(typeof jQuery != 'undefined') {
	jQuery.fn.humane_dates = function(){
		return this.each(function(){
			var date = humane_date(this.title);
			if(date && jQuery(this).text() != date) // don't modify the dom if we don't have to
				jQuery(this).text(date);
		});
	};
}
