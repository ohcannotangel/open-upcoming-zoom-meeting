# upcomingZoomStarter

check your calendar and open upcoming zoom meeting.

# Installation
1. Open upcomingZoomStarter.applescript with "Script Editor" app (default)

2. Export as Application
   - Name: UpcomingZoomStarter
   - File Format: Application
   - Path: /Applications

3. Open App and allow access to your contacts, calendar and chrome

 
# Usage

```
/crontab -e

14,29,44,59 9-21 * * 1-5 open -a UpcomingZoomStarter
```
 
 
# Note

## Default paramater
- futureThreshold: 15 (mins)
- pastThreshold: 10 (mins)

 
# License
 
under [MIT license](https://en.wikipedia.org/wiki/MIT_License).
 
