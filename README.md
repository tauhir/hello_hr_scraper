# hello_hr_scraper

This app extracts all the company, payroll & employee data from a [HelloHR](https://app.hellohr.co.za/) account. 

Running the app:
* Clone the respository
* Install ruby (app was built in 2.6.9)
* Navigate to the cloned directory
* Install the Get cookies.txt chrome extension found [here](https://chrome.google.com/webstore/detail/get-cookiestxt/bgaddhkoddajcdgocldbbfleckgcbcid)
* With the extension active, login to HelloHR and export the cookies
* Move the cookie file to your working folder
* Run the app with the cookie filename as an argument:
** ruby scraper.rb {{Filename here}}
** e.g ruby scraper.rb hellohr.co.za_cookies.txt
* The app generates a JSON file containing all the data 
