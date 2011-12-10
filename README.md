Pilcrow
=======

Pilcrow is a simple webapp you can use to organize your home library. Enter book ISBN numbers (Buy a usb barcode scanner. $40. Fun.) and the app will retrieve book data via the [Google Book APIs](http://code.google.com/apis/books/)

Installation
------------

In Terminal (on OS X):

	git checkout https://github.com/cproctor/Pilcrow.git
	cd pilcrow
	bundle install
	ruby ./pilcrow

In your web browser:

	localhost:4567
	
Now you're ready to [deploy to Heroku](http://devcenter.heroku.com/articles/quickstart) if you want a site everyone can see.
	
	
Issues
------

Occasionally, your app ends up on a Heroku server that the Google APIs don't recognize as being in the US, so they block your access. The easiest thing is to make an insignificant commit and redeploy.

License
-------

Copyright (c) 2011 Chris Proctor

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.