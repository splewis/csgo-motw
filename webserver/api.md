URL: http://csgo-motw.appspot.com?{params}

Parameters
==========

---------
timestamp
- an integer in seconds since 1970
- default: current time (in UTC)

------
league
- league to match motw from (accepted values: 'esea', 'cevo')
- default: esea

-----------
expiration
- time in seconds a map record should be no longer accepted as a map of the week,
  after which the default map will be used
- default: 1209600 (2 weeks)

-------
default
- fallback map if the matching recent is past 'expiration' seconds from the input timestamp
- default: de_dust2
