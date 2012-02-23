# Cornflake

The purpose is to create a Mexican Wave via the medium of mobile phones

It is sonar- and ad-hoc-network-based.

We create a sonar ping that is broadcast to all phones that are within a listening distance, then have them report back at what time they heard the ping over an ad-hoc local network connection.  From there, the coordinator device (of which there should only be one) sends messages back to the connected devices informing them to go crazy (vibrate, light up, turn flashes on, make noises) at their allotted time, which depends on the calculated distance.  We hope that people will join in with their phones.

Whilst obviously infeasible for large events due to devices not being all in bluetooth range or connected to the same wifi network, the idea of a spontaneous mexican wave of phone camera flashes around a big venue is surprisingly appealing.  Let's hope development goes in that direction...


This is a project by [Russ Anderson](http://github.com/rux/) and [Tom York](http://github.com/tyork/) of [Yell Labs](http://www.yell.com/mobilephones/yell-labs.html).  It was started for the February 2011 Hack Day.  It won a "special mention" but failed to take the top prize.  Considering it wasn't working for the presentation, this does seem fair of the judges.

It is called "Cornflake" because so many people have [forgotten what happens when you eat Kellogg's Corn Flakes](http://www.youtube.com/watch?v=cygv7h6E1KY).  