# Lyft Programming Challenge
---
## Computing the minimum detour distance between four points

From the problem spec:

> Calculate the detour distance between two different rides. Given four latitude / longitude pairs, where driver one is traveling from point A to point B and driver two is traveling from point C to point D, write a function (in your language of choice) to calculate the shorter of the detour distances the drivers would need to take to pick-up and drop-off the other driver.

In other words, the detour distance is the extra distance a driver would make if she were going from point X to point Y and had to stop at points U and W along the way. Here, one driver is going from A to B and another is going from C to D. So the minimum detour distance is the minimum of ACDB - AB and CABD - CD.

The solution is a Ruby script that uses the Bing Routes API to compute the distance between four coordinates.

Example usage:

1. Obtain a Bing Maps API key (instructions [here][1]) and save it to `config/key.txt`
2. Look up the coordinates of the area you're interested in (for example, [here][2]). The below example computes the minimum detour distance between Seattle, Sunnyvale, Austin, and NYC.
3. Plug them into the script (note no space between the latitude and longitude):
```
> ruby dist_calc.rb -A 47.606209,-122.332071 -B 37.368830,-122.03635 -C 30.267153,-97.743061 -D 40.714353,-74.005973
Calculating...
The minimum detour distance is 4071.85 mi.
```

If the coordinates are all reachable, the script prints out the minimum detour distance in miles and exits with 0. If the coordinates aren't reachable, or there is a problem communicating with the routing server, or the API key is invalid, the script prints out an error message and exits with a non-zero status code.

  [1]: http://msdn.microsoft.com/en-us/library/ff428642.aspx
  [2]: http://www.latlong.net/
