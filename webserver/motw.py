import bisect
import datetime
import json
import time

# Global constants.
DATA_FILE = 'data.json'
TIME_FORMAT = '%Y/%m/%d'
DEFAULT_MAP = 'de_dust2'
DEFAULT_EXPIRATION = 14*24*60*60
DEFAULT_LEAGUE = 'esea'

# Global container for per-map data.
# This is meant to store league->list of instances
# of the Map class below.
map_data = {}


# This class really just wraps a tuple(time, name), but gives a comparison
# function based only on the timestamp difference, which lets us sort
# a list of these in time-increasing order.
class Map:

    def __init__(self, time, name=''):
        self.time = time
        self.name = name

    def __cmp__(self, other):
        # TODO: this should really be inverted, right now it sorts
        # in descending order while it should be ascending.
        return other.time - self.time

    def __repr__(self):
        return str((self.time, self.name))


def parse_map_data_input(map_dict, time_format):
    data = {}
    for league in map_dict:
        league_data = []
        for str_date in map_dict[league]:
            # If already a timestamp value, use that.
            timestamp = 0
            try:
                timestamp = int(str_date)
            except ValueError:
                time_result = datetime.datetime.strptime(str_date, time_format)
                timestamp = int(time.mktime(time_result.timetuple()))
                map_name = map_dict[league][str_date]
            league_data.append(Map(timestamp, map_name))
        data[league] = sorted(league_data)
    return data


def read_map_data(filename, time_format):
    try:
        with open(filename) as f:
            text = f.read()
            json_data = json.loads(text)
            return parse_map_data_input(json_data, time_format)
    except IOError, ValueError:
        return {DEFAULT_LEAGUE: [Map(0, DEFAULT_MAP)]}


def get_motw(map_data, timestamp, league=DEFAULT_LEAGUE,
             expiration=DEFAULT_EXPIRATION, default_map=DEFAULT_MAP):
    try:
        index = bisect.bisect_left(map_data[league], Map(timestamp))
        # No matching timestamp.
        if index < 0 or index >= len(map_data[league]):
            return default_map
        map_result = map_data[league][index]
        dt = timestamp - map_result.time
        if dt > expiration:
            return default_map
        else:
            return map_data[league][index].name
    except KeyError:
        return default_map
