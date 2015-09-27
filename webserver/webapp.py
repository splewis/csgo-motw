import motw
import time
import webapp2

# Global constants.
DATA_FILE = 'data.json'
TIME_FORMAT = '%Y/%m/%d'

# Global container for per-map data.
# This is meant to store league->list of instances
# of the Map class below.
map_data = {}

class MainHandler(webapp2.RequestHandler):

    def get(self):
        # Get URL params.
        try:
            timestamp = int(self.request.get('timestamp', time.time()))
        except ValueError:
            timestamp = int(time.time())

        league = self.request.get('league', motw.DEFAULT_LEAGUE)
        default_map = self.request.get('default', motw.DEFAULT_MAP)

        try:
            expiration = int(self.request.get('expiration', motw.DEFAULT_EXPIRATION))
        except ValueError:
            expiration = motw.DEFAULT_EXPIRATION

        try:
            time_offset = int(self.request.get('offset', 0))
        except ValueError:
            time_offset = 0

        result_map = motw.get_motw(
            map_data, timestamp + time_offset, league, expiration, default_map)
        self.response.write(result_map)


map_data = motw.read_map_data(DATA_FILE, TIME_FORMAT)
app = webapp2.WSGIApplication([
    ('/', MainHandler),
], debug=True)
