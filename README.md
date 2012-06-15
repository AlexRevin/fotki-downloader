fotki-downloader
================

Fotki.com original file downloader

Hello folks

As you might have heard, Fotki.com service has got into trouble and you cannot download your original files without paying extra to them.

This tiny ruby script will try to fetch all your original photos without accessing FTP, but running it might be tricky.

First of all, you are cool when you have a Mac or Linux. I have never tried running this script on Windows and cannot give any recommendation on that topic, in other words, you are on your own.

If you have a Mac or Linux, make sure you know how to open up console in Linux or Terminal.app in Mac. 

Then you'd have to install Nokogiri gem for ruby:

`sudo gem install nokogiri`

If you are on Mac and don't have either [MacPorts](http://www.macports.org/) or [HomeBrew](http://mxcl.github.com/homebrew/)) installed - you have to install any of them and then:

`sudo port install wget`
or 
`brew install wget`

Linux users should not do any of above, though you have to check if wget is installed in your system and install it if it's not


And then you are ready to go

1. Create a directory you want to store your images at
2. Find it in shell e.g. `cd /path/to/my/images`. If you have created this directory in your Home, then most likely you would be able to find it with ~/images
3. Type `pwd` and copy the output, the output is actually your images directory path
4. With terminal, go to the directory, where you have a downloader.rb script and type the following:
    `ruby downloader.rb -u yourusername -p yourpassword -d imagesdirectory`

If you were lucky and start were in the right position, albums would be found, their structure re-created localy and original images would start downloading.

P.S.

This script was written in 2009, just for fun. As it became actual at the moment, I found it, tuned it up, tested and uploaded. I am not going to support this code at all, so feel free to fork it and fix it in case it stops working. You can make a pull-request and I would merge in with my branch but I shall not make any fixes and workarounds.