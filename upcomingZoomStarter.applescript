ObjC.import('AppKit')
ObjC.import('EventKit')


///////////////////////////////////

const futureThreshold = 15
const pastThreshold = 10
const zoomRegex = /https:\/\/([a-z0-9]+\.)?zoom\.us\/j\/\d+/g

///////////////////////////////////


const store = $.EKEventStore.alloc.init

// check for/request access to user's calendars
function haveAccess() {
	let ok = null

	store.requestAccessToEntityTypeCompletion($.EKEntityTypeEvent, function(granted, err) {
		ok = granted
	})
	while (ok === null) {
		delay(0.01)
	}
	return ok
}


// load events for number of coming days
function getEvents(days) {
	// retrieve all accounts & their calendars
	let calendars = $.NSMutableArray.alloc.init
	
	console.log(calendars)

	ObjC.unwrap(store.sources).forEach(source => {
		console.log(`${ObjC.unwrap(source.title)}`)

		let cals = source.calendarsForEntityType($.EKEntityTypeEvent).allObjects
		ObjC.unwrap(cals).forEach(calendar => {
			console.log(`  +-- ${ObjC.unwrap(calendar.title)}`)
			calendars.addObject(calendar)
		})
	})
	
	// retrieve all events from start of today until n days from now
	var endDateComponents = $.NSDateComponents.alloc.init
	endDateComponents.day = days
	let endDate = $.NSCalendar.currentCalendar.dateByAddingComponentsToDateOptions(endDateComponents, $.NSDate.now, 0)
	let predicate = store.predicateForEventsWithStartDateEndDateCalendars($.NSCalendar.currentCalendar.startOfDayForDate($.NSDate.now), endDate, calendars)
	
	let events = ObjC.unwrap(store.eventsMatchingPredicate(predicate))
	return events
}

function eventFilter(events, futureThreshold, pastThreshold) {

	
	let now = new Date()
	now.setSeconds(0)
	
	let condTo = new Date()
	condTo.setMinutes(now.getMinutes() + futureThreshold)

	let condFrom = new Date()
	condFrom.setMinutes(now.getMinutes() - pastThreshold)

	return events.filter(event => {
	
		const evEnd = Date.parse(event.end_date)
		const evStart = Date.parse(event.start_date)

		// doesn't contain a zoom URL.
		if(event.location.match(zoomRegex) <= 0 && event.url.match(zoomRegex) <= 0 && event.notes.match(zoomRegex) <= 0) {
			return false
		}

		// has already done
		if(evEnd < now) {
			return false
		}

		// doesn't start within n minutes (n=futureThreadshold)
		if(evStart > condTo) {
			return false
		}

		// has already started more than n minutes ago (n=pastThreadshold)
		if(evStart < condFrom) {
			return false
		}
		
		return true

	})

}


function openWithChromeNewTab(url) {

  const chrome = Application('Google Chrome');

  let window, tab, tabIndex;

  if(chrome.windows.length === 0) {
    window = chrome.Window().make();
    tab = window.tabs[0];
    tabIndex = 1;

  } else {
    window = chrome.windows[0];
    window.tabs.push(tab = chrome.Tab());
    tabIndex = window.tabs.length;
  }

  tab.url.set(url);
  window.activeTabIndex.set(tabIndex);

}


function run() {

	if (!haveAccess()) {
		return JSON.stringify({error: 'No Access to Calendars', events: []})
	}

	let days = 1,
		events = [],
		formatter = $.NSISO8601DateFormatter.alloc.init
		
	// convert all times to local time
	formatter.timeZone = $.NSTimeZone.localTimeZone
	
	let ekEvents = getEvents(days)
	console.log(ekEvents)

	ekEvents.forEach(event => {
		if (event.status === $.EKEventStatusCanceled) return
		if (event.allDay) return
				
		let title = ObjC.unwrap(event.title),
			url = ObjC.unwrap(event.URL.absoluteString),
			notes = ObjC.unwrap(event.notes),
			location = ObjC.unwrap(event.location)
			
		// ensure these have values otherwise they'll be omitted from
		// JSON output because they're undefined
		title = title ? title : ''
		url = url ? url : ''
		notes = notes ? notes : ''
		location = location ? location : ''

		events.push({
			uid: ObjC.unwrap(event.eventIdentifier),
			title: title,
			url: url,
			notes: notes,
			location: location,
			account: ObjC.unwrap(event.calendar.source.title),
			calendar: ObjC.unwrap(event.calendar.title),
			calendar_id: ObjC.unwrap(event.calendar.calendarIdentifier),
			start_date: ObjC.unwrap(formatter.stringFromDate(event.startDate)),
			end_date: ObjC.unwrap(formatter.stringFromDate(event.endDate)),
		})
	})
	
	events.sort((a, b) => {
		if (a.start_date < b.start_date) return -1
		if (a.start_date > b.start_date) return 1
		if (a.title < b.title) return -1
		if (a.title > b.title) return 1
		return 0
	})
	

	filteredEvents = eventFilter(events, futureThreshold, pastThreshold)

	for(var i=0; i < filteredEvents.length; i++) {

		const event = filteredEvents[i]
	
		// open dialog
		const app = Application('Finder');
		app.includeStandardAdditions = true

		const dialogText = "まもなく開始する Zoom ミーティングがあります。\nURLを開きますか？" +
		 "\n\ntitle: " + event.title + 
		 "\nstart:：" + event.start_date + 
		 "\nURL:" + event.location

		const res = app.displayDialog(dialogText, {
		    buttons: ["キャンセル", "はい"],
		    defaultButton: "はい",
		})
		
		// open url with chrome
		if(res.buttonReturned == "はい") {
			openWithChromeNewTab(event.location)
			break
		}
	}

}
