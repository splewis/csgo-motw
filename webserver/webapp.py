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
        league = self.request.get('league', motw.DEFAULT_LEAGUE)
        default_map = self.request.get('default', motw.DEFAULT_MAP)

        try:
            timestamp = int(self.request.get('timestamp', time.time()))
        except ValueError:
            self.error(400)
            self.response.write('Illegal value for parameter \"timestamp\"')
            return

        try:
            expiration = int(self.request.get('expiration', motw.DEFAULT_EXPIRATION))
        except ValueError:
            self.error(400)
            self.response.write('Illegal value for parameter \"expiration\"')
            return

        try:
            time_offset = int(self.request.get('offset', 0))
        except ValueError:
            self.error(400)
            self.response.write('Illegal value for parameter \"offset\"')
            return

        result_map = motw.get_motw(
            map_data, timestamp + time_offset, league, expiration, default_map)
        self.response.write(result_map)


map_data = motw.read_map_data(DATA_FILE, TIME_FORMAT)
app = webapp2.WSGIApplication([
    ('/', MainHandler),
], debug=True)
