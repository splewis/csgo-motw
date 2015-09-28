import motw
import unittest


class TestMOTW(unittest.TestCase):

    def get_map_dict(self):
        return {
            "esea": {
                "2015/09/06": "de_dust2",     # 1441497600
                "2015/09/13": "de_train",     # 1442102400
                "2015/09/20": "de_mirage",    # 1442707200
                "2015/09/27": "de_cbble",     # 1443312000
                "2015/10/04": "de_overpass",  # 1443916800
                "2015/10/11": "de_mirage",    # 1444521600
                "2015/10/18": "de_inferno",   # 1445126400
                "2015/10/25": "de_cache",     # 1445731200
                "2015/11/01": "de_dust2",     # 1446336000
            },
            "cevo": {
                "2015/08/23": "de_cbble",     # 1440288000
                "2015/08/30": "de_season",    # 1440892800
                "2015/09/06": "de_inferno",   # 1441497600
                "2015/09/13": "de_train",     # 1442102400
                "2015/09/20": "de_cache",     # 1442707200
                "2015/09/27": "de_overpass",  # 1443312000
                "2015/10/04": "de_dust2",     # 1443916800
                "2015/10/11": "de_mirage",    # 1444521600
            },
        }

    def get_map_data(self):
        return motw.parse_map_data_input(self.get_map_dict(), '%Y/%m/%d')

    def test_parse_map_data_input(self):
        expected = {
            "esea": [
                (1441497600, "de_dust2"),
                (1442102400, "de_train"),
                (1442707200, "de_mirage"),
                (1443312000, "de_cbble"),
                (1443916800, "de_overpass"),
                (1444521600, "de_mirage"),
                (1445126400, "de_inferno"),
                (1445731200, "de_cache"),
                (1446336000, "de_dust2"),
            ],
            "cevo": [
                (1440288000, "de_cbble"),
                (1440892800, "de_season"),
                (1441497600, "de_inferno"),
                (1442102400, "de_train"),
                (1442707200, "de_cache"),
                (1443312000, "de_overpass"),
                (1443916800, "de_dust2"),
                (1444521600, "de_mirage"),
            ],
        }
        actual = motw.parse_map_data_input(self.get_map_dict(), '%Y/%m/%d')
        self.assertEqual(expected, motw.parse_map_data_input(self.get_map_dict(), '%Y/%m/%d'))

    def test_find_matching_map(self):
        map_list = [
            (0, 'a'),
            (1, 'b'),
            (3, 'c'),
            (6, 'd'),
            (10, 'e'),
        ]
        self.assertEqual(0, motw.find_matching_map(map_list, 0, 'default'))
        self.assertEqual(1, motw.find_matching_map(map_list, 1, 'default'))
        self.assertEqual(1, motw.find_matching_map(map_list, 2, 'default'))
        self.assertEqual(2, motw.find_matching_map(map_list, 3, 'default'))
        self.assertEqual(2, motw.find_matching_map(map_list, 4, 'default'))
        self.assertEqual(2, motw.find_matching_map(map_list, 5, 'default'))
        self.assertEqual(3, motw.find_matching_map(map_list, 6, 'default'))
        self.assertEqual(3, motw.find_matching_map(map_list, 7, 'default'))
        self.assertEqual(3, motw.find_matching_map(map_list, 8, 'default'))
        self.assertEqual(3, motw.find_matching_map(map_list, 9, 'default'))
        self.assertEqual(4, motw.find_matching_map(map_list, 10, 'default'))
        self.assertEqual(4, motw.find_matching_map(map_list, 11, 'default'))

    def test_get_motw(self):
        map_data = self.get_map_data()
        # Check before any map record time exists.
        self.assertEqual('default', motw.get_motw(map_data, 1, 'esea', 1000000, 'default'))

        # Check normal time intervals near the start dates for each map.
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1441497600, 'esea', 1000000, 'default'))
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1442102400 - 1, 'esea', 1000000, 'default'))

        self.assertEqual('de_train', motw.get_motw(map_data, 1442102400, 'esea', 1000000, 'default'))
        self.assertEqual('de_train', motw.get_motw(map_data, 1442102400 + 1, 'esea', 1000000, 'default'))
        self.assertEqual('de_train', motw.get_motw(map_data, 1442707200 - 1, 'esea', 1000000, 'default'))

        self.assertEqual('de_mirage', motw.get_motw(map_data, 1442707200, 'esea', 1000000, 'default'))
        self.assertEqual('de_cbble', motw.get_motw(map_data, 1443312000, 'esea', 1000000, 'default'))
        self.assertEqual('de_overpass', motw.get_motw(map_data, 1443916800, 'esea', 1000000, 'default'))
        self.assertEqual('de_mirage', motw.get_motw(map_data, 1444521600, 'esea', 1000000, 'default'))
        self.assertEqual('de_inferno', motw.get_motw(map_data, 1445126400, 'esea', 1000000, 'default'))
        self.assertEqual('de_cache', motw.get_motw(map_data, 1445731200, 'esea', 1000000, 'default'))
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1446336000, 'esea', 1000000, 'default'))

    def test_get_motw_expiration(self):
        map_data = self.get_map_data()
        # Get after a map with a very short expiration time, so it uses the default.
        self.assertEqual('de_dust2', motw.get_motw(map_data, 1441497600 + 100, 'esea', 100, 'default'))
        self.assertEqual('default', motw.get_motw(map_data, 1441497600 + 100, 'esea', 99, 'default'))

        self.assertEqual('de_mirage', motw.get_motw(map_data, 1444521600 + 100, 'cevo', 100, 'default'))
        self.assertEqual('default', motw.get_motw(map_data, 1444521600 + 100, 'cevo', 99, 'default'))


if __name__ == '__main__':
    unittest.main()
