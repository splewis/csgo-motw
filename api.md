URL: http://csgo-motw.appspot.com?{params}

Parameters
==========

------
league
- league to match motw from (accepted values: 'esea', 'cevo')
- default: esea

---------
timestamp
- an integer in seconds since 1970
- default: current time (in UTC)

---------
timestamp
- an integer in seconds that will be added to the ``timestamp`` parameter
- default: 0

-----------
expiration
- time in seconds a map record should be no longer accepted as a current map of the week
  after which the default map will be used
- default: 1209600 (2 weeks)

-------
default
- fallback map if the matching recent is past 'expiration' seconds from the input timestamp
- default: de_dust2
