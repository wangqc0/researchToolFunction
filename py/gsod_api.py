# Reference:
# https://www.ncei.noaa.gov/support/access-search-service-api-user-documentation
# https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation

# function: given location (longitude and latitude) and year, return the daily weather data in closest weather station
def get_closest_station_summary(longitude, latitude, year, radius = .5, vartype = ['TEMP', 'MAX', 'MIN', 'PRCP', 'VISIB', 'WDSP']):
    # longitude: longitude of the point
    # latitude: latitude of the point
    # year: year of data to download
    # radius: radius of the box to search the closest weather station
    # vartype: data type to download (within a pre-determined comprehensive list)
    vartype_all = ['DEWP', 'FRSHTT', 'GUST', 'MAX', 'MIN', 'MXSPD', 'PRCP', 'SLP', 'SNDP', 'STP', 'TEMP', 'VISIB', 'WDSP']
    if set(vartype) - set(vartype_all) != set():
        raise ValueError('Variable type must be within the following: ' + ', '.join(vartype_all) + '.')
    link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year}-01-01&endDate={year}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit=1'.format(year = year, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius)
    # find the station
    station_found = False
    while not station_found:
        with urllib.request.urlopen(link_search) as url:
            info = json.loads(url.read().decode())
        if info['count'] == 0:
            # if not found within the specified radius, expand the searching by doubling the searching box
            radius *= 2
            link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year}-01-01&endDate={year}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit=1'.format(year = year, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius)
        else:
            station_code = info['stations']['buckets'][0]['key']
            station_longitude = info['results'][0]['boundingPoints'][0]['point'][0]
            station_latitude = info['results'][0]['boundingPoints'][0]['point'][1]
            station_found = True
    # download data
    link_download = 'https://www.ncei.noaa.gov/access/services/data/v1?dataset=global-summary-of-the-day&dataTypes={vartype_str}&stations={station}&startDate={year}-01-01&endDate={year}-12-31&includeAttributes=false&format=json'.format(vartype_str = ','.join(vartype), station = station_code, year = year)
    with urllib.request.urlopen(link_download) as url:
        data_json = json.loads(url.read().decode())
    data = pd.json_normalize(data_json)
    return {
        'station_code': station_code,
        'station_longitude': station_longitude,
        'station_latitude': station_latitude,
        'data': data
    }

# function: given location (longitude and latitude) and year, return the information of the closest weather station
def get_closest_station(longitude, latitude, year_begin, year_end, min_num_year, radius = .5, max_radius = 4):
    # longitude: longitude of the point
    # latitude: latitude of the point
    # year_begin: beginning year of the data to download
    # year_end: ending year of the data to download
    # min_num_year: allowed minimum number of years with available data
    # radius: radius of the box to search the closest weather station
    # max_radius: allowed maximum radius of the box to search
    num_year = year_end - year_begin + 1
    link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year_begin}-01-01&endDate={year_end}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit={num_year}'.\
        format(year_begin = year_begin, year_end = year_end, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius, num_year = num_year)
    # find the station
    station_found = False
    while not station_found:
        with urllib.request.urlopen(link_search) as url:
            info = json.loads(url.read().decode())
        # find stations with available data in all years
        stations_found = pd.json_normalize(info['stations']['buckets'])
        if (len(stations_found) == 0) & (radius <= max_radius):
            # if not found within the specified radius, expand the searching by doubling the searching box
            radius *= 2
            link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year_begin}-01-01&endDate={year_end}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit={num_year}'.\
                format(year_begin = year_begin, year_end = year_end, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius, num_year = num_year)
        elif (stations_found.docCount.max() < min_num_year) & (radius <= max_radius):
            # if not found a station with sufficient years of observations within the specified radius, expand the searching by doubling the searching box
            radius *= 2
            link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year_begin}-01-01&endDate={year_end}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit={num_year}'.\
                format(year_begin = year_begin, year_end = year_end, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius, num_year = num_year)
        else:
            try:
                stations_found = stations_found[stations_found['docCount'] == stations_found['docCount'].max()].reset_index(drop = True)
                # choose the first one among all available stations fulfilling the criteria
                station_code = stations_found['key'][0]
                # obtain the longitude, latitude, and name of the chosen station
                link_geolocate = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year_begin}-01-01&endDate={year_end}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&stations={station}&limit=1'.\
                    format(year_begin = year_begin, year_end = year_end, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius, station = station_code)
                with urllib.request.urlopen(link_geolocate) as url:
                    info_station = json.loads(url.read().decode())
                station_longitude = info_station['results'][0]['boundingPoints'][0]['point'][0]
                station_latitude = info_station['results'][0]['boundingPoints'][0]['point'][1]
                station_name = info_station['results'][0]['stations'][0]['name']
                station_num_year = info_station['count']
                station_year_begin = info_station['startDate']
                station_year_end = info_station['endDate']
            except:
                station_code = np.nan
                station_longitude = np.nan
                station_latitude = np.nan
                station_name = np.nan
                station_num_year = np.nan
                station_year_begin = np.nan
                station_year_end= np.nan
            station_found = True
    return {
        'station_code': station_code,
        'station_longitude': station_longitude,
        'station_latitude': station_latitude,
        'station_name': station_name,
        'station_num_year': station_num_year,
        'station_year_begin': station_year_begin,
        'station_year_end': station_year_end
    }

# function: given a weather station code and year, return the daily weather data
def get_station_code_summary(station_code, year, vartype = ['TEMP', 'MAX', 'MIN', 'PRCP', 'VISIB', 'WDSP']):
    # station_code: code of the weather station
    # year: year of data to download
    # vartype: data type to download (within a pre-determined comprehensive list)
    vartype_all = ['DEWP', 'FRSHTT', 'GUST', 'MAX', 'MIN', 'MXSPD', 'PRCP', 'SLP', 'SNDP', 'STP', 'TEMP', 'VISIB', 'WDSP']
    if set(vartype) - set(vartype_all) != set():
        raise ValueError('Variable type must be within the following: ' + ', '.join(vartype_all) + '.')
    # download data
    link_download = 'https://www.ncei.noaa.gov/access/services/data/v1?dataset=global-summary-of-the-day&dataTypes={vartype_str}&stations={station}&startDate={year}-01-01&endDate={year}-12-31&includeAttributes=false&format=json'.format(vartype_str = ','.join(vartype), station = station_code, year = year)
    with urllib.request.urlopen(link_download) as url:
        data_json = json.loads(url.read().decode())
    data = pd.json_normalize(data_json)
    return data

# function: given location (longitude and latitude) and year, return the daily weather data in closest weather station from csv repository
def get_closest_station_summary_from_repository(longitude, latitude, year, radius = .5):
    # longitude: longitude of the point
    # latitude: latitude of the point
    # year: year of data to download
    # radius: radius of the box to search the closest weather station
    link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year}-01-01&endDate={year}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit=1'.format(year = year, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius)
    # find the station
    station_found = False
    while not station_found:
        with urllib.request.urlopen(link_search) as url:
            info = json.loads(url.read().decode())
        if info['count'] == 0:
            # if not found within the specified radius, expand the searching by doubling the searching box
            radius *= 2
            link_search = 'https://www.ncei.noaa.gov/access/services/search/v1/data?dataset=global-summary-of-the-day&startDate={year}-01-01&endDate={year}-12-31&bbox={north},{west},{south},{east}&keywords=temperature&limit=1'.format(year = year, north = latitude + radius, west = longitude - radius, south = latitude - radius, east = longitude + radius)
        else:
            station_code = info['stations']['buckets'][0]['key']
            station_longitude = info['results'][0]['boundingPoints'][0]['point'][0]
            station_latitude = info['results'][0]['boundingPoints'][0]['point'][1]
            station_file_path = info['results'][0]['filePath']
            station_found = True
    # download data
    link_download = 'https://www.ncei.noaa.gov/' + station_file_path
    data = pd.read_csv(link_download)
    return {
        'station_code': station_code,
        'station_longitude': station_longitude,
        'station_latitude': station_latitude,
        'data': data
    }
