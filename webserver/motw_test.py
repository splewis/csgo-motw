import motw
import unittest


class TestMOTW(unittest.TestCase):

    def get_map_dict(self):
        return {
            "esea": {
                "2015/09/06": "de_dust2",     # 1441515600
                "2015/09/13": "de_train",     # 1442120400
                "2015/09/20": "de_mirage",    # 1442725200
                "2015/09/27": "de_cbble",     # 1443330000
                "2015/10/04": "de_overpass",  # 1443934800
                "2015/10/11": "de_mirage",    # 1444539600
                "2015/10/18": "de_inferno",   # 1445144400
                "2015/10/25": "de_cache",     # 1445749200
                "2015/11/01": "de_dust2",     # 1446357600
            },
            "cevo": {
                "2015/08/23": "de_cbble",     # 1440306000
                "2015/08/30": "de_season",    # 1440910800
                "2015/09/06": "de_inferno",   # 1441515600
                "2015/09/13": "de_train",     # 1442120400
                "2015/09/20": "de_cache",     # 1442725200
                "2015/09/27": "de_overpass",  # 1443330000
                "2015/10/04": "de_dust2",     # 1443934800
                "2015/10/11": "de_mirage",    # 1444539600
            },
        }

    def get_map_data(self):
        return motw.parse_map_data_input(self.get_map_dict(), '%Y/%m/%d')

    def test_parse_map_data_input(self):
        expected = {
            "esea": [
                motw.Map(1446357600, "de_dust2"),
                motw.Map(1445749200, "de_cache"),
                motw.Map(1445144400, "de_inferno"),
                motw.Map(1444539600, "de_mirage"),
                motw.Map(1443934800, "de_overpass"),
                motw.Map(1443330000, "de_cbble"),
                motw.Map(1442725200, "de_mirage"),
                motw.Map(1442120400, "de_train"),
                motw.Map(1441515600, "de_dust2"),
            ],
            "cevo": [
                motw.Map(1444539600, "de_mirage"),
                motw.Map(1443934800, "de_dust2"),
                motw.Map(1443330000, "de_overpass"),
                motw.Map(1442725200, "de_cache"),
                motw.Map(1442120400, "de_train"),
                motw.Map(1441515600, "de_inferno"),
                motw.Map(1440910800, "de_season"),
                motw.Map(1440306000, "de_cbble"),
            ],
        }
        actual = motw.parse_map_data_input(self.get_map_dict(), '%Y/%m/%d')
        self.assertEqual(expected, motw.parse_map_data_input(self.get_map_dict(), '%Y/%m/%d'))

    def test_get_motw(self):
        map_data = self.get_map_data()
        # Check before any map record time exists.
        self.assertEqual('default', motw.get_motw(map_data, 1, 'esea', 1000000, 'default'))

        # Check normal time intervals near the start dates for each map.
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1441515600, 'esea', 1000000, 'default'))
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1442120400 - 1, 'esea', 1000000, 'default'))

        self.assertEqual('de_train', motw.get_motw(map_data, 1442120400, 'esea', 1000000, 'default'))
        self.assertEqual('de_train', motw.get_motw(map_data, 1442120400 + 1, 'esea', 1000000, 'default'))
        self.assertEqual('de_train', motw.get_motw(map_data, 1442725200 - 1, 'esea', 1000000, 'default'))

        self.assertEqual('de_mirage', motw.get_motw(map_data, 1442725200, 'esea', 1000000, 'default'))
        self.assertEqual('de_cbble', motw.get_motw(map_data, 1443330000, 'esea', 1000000, 'default'))
        self.assertEqual('de_overpass', motw.get_motw(map_data, 1443934800, 'esea', 1000000, 'default'))
        self.assertEqual('de_mirage', motw.get_motw(map_data, 1444539600, 'esea', 1000000, 'default'))
        self.assertEqual('de_inferno', motw.get_motw(map_data, 1445144400, 'esea', 1000000, 'default'))
        self.assertEqual('de_cache', motw.get_motw(map_data, 1445749200, 'esea', 1000000, 'default'))
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1446357600, 'esea', 1000000, 'default'))

    def test_get_motw_expiration(self):
        map_data = self.get_map_data()
        # Get after a map with a very short expiration time, so it uses the default.
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1441515600 + 100, 'esea', 100, 'default'))
        self.assertEqual('default', motw.get_motw(map_data, 1441515600 + 100, 'esea', 99, 'default'))

        self.assertEqual('de_mirage', motw.get_motw(map_data, 1444539600 + 100, 'cevo', 100, 'default'))
        self.assertEqual('default', motw.get_motw(map_data, 1444539600 + 100, 'cevo', 99, 'default'))


if __name__ == '__main__':
    unittest.main()
