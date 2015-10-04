import bisect
import calendar
import collections
import datetime
import json
import time

# Global constants.
DEFAULT_MAP = 'de_dust2'
DEFAULT_EXPIRATION = 7*24*60*60  # 1 week in seconds
DEFAULT_LEAGUE = 'esea'
MapRecord = collections.namedtuple('MapRecord', ['timestamp', 'name'])


def read_map_data(filename, time_format):
    """Returns a dictionary of map data information from a file."""
    try:
        with open(filename) as f:
            text = f.read()
            json_data = json.loads(text)
            return parse_map_data_input(json_data, time_format)
    except IOError, ValueError:
        return {}


def parse_map_data_input(map_dict, time_format):
    """
    Parse a map dict of league->[time, map] keyvalues into a dictionary of
    league to lists of (integer timestamp, mapname) tuples.
    """
    data = {}
    for league in map_dict:
        league_data = []
        for str_date in map_dict[league]:
            timestamp = 0
            try:
                # If already a timestamp value, use that.
                timestamp = int(str_date)
            except ValueError:
                # Otherwise, parse it using the time format.
                try:
                    time_result = datetime.datetime.strptime(
                        str_date, time_format)
                    timestamp = int(
                        calendar.timegm(time_result.utctimetuple()))
                    map_name = map_dict[league][str_date]
                except ValueError:
                    print 'Failed to parse date {}' % str_date
            league_data.append(MapRecord(timestamp, map_name))
        data[league] = sorted(league_data)
    return data


def find_matching_map(map_record_list, timestamp, default_map):
    """
    Returns the index of the map whose start time is greater than
    or equal to the input timestamp from the map_record_list.
    Returns -1 on error.
    """
    if not map_record_list:
        return -1
    time_list = [map_record.timestamp for map_record in map_record_list]
    return bisect.bisect(time_list, timestamp) - 1


def get_motw(map_data, timestamp, league=DEFAULT_LEAGUE,
             expiration=DEFAULT_EXPIRATION, default_map=DEFAULT_MAP):
    """
    Returns a map of the week from the parsed map data from a result of
    read_map_data call.
    """
    try:
        index = find_matching_map(map_data[league], timestamp, default_map)
        # No matching timestamp.
        if index < 0 or index >= len(map_data[league]):
            return default_map
        result_timestamp, result_map = map_data[league][index]
        dt = timestamp - result_timestamp
        if dt > expiration:
            return default_map
        else:
            return result_map
    except KeyError:
        return default_map
