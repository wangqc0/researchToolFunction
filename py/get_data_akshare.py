# The programme downloads the daily information of futures assets of China from AKShare.
# You can revise the script below to download the information of different assets.
# Reference: https://akshare.akfamily.xyz

import os
import datetime
import akshare as ak
import pandas as pd

format_market = False
confirmation_market = False
list_market = ['CFFEX', 'SHFE', 'INE', 'CZCE', 'DCE', 'GFEX']
while confirmation_market == False:
	print('Enter the market (available: {}):'.format(', '.join(list_market)))
	market_input = input()
	while format_market == False:
		if market_input in list_market:
			format_market = True
		else:
			print('The market entered is unavailable. Please re-enter (available: {}):'.format(', '.join(list_market)))
			market_input = input()
	print('The market selected is: {}. Enter (Y/y) to confirm.'.format(market_input))
	confirmed = input()
	if confirmed in ['Y', 'y']:
		confirmation_market = True
	else:
		format_market = False

format_date_begin = False
format_date_end = False
confirmation_date = False
while confirmation_date == False:
	print('Enter the starting date (YYYYMMDD):')
	date_begin = input()
	while format_date_begin == False:
		if len(date_begin) == 8:
			try:
				format_date_begin_validation = datetime.datetime.strptime(date_begin, '%Y%m%d')
				format_date_begin = True
			except:
				print('The date is invalid. Please re-enter (YYYYMMDD):')
				date_begin = input()
		else:
			print('The date is invalid. Please re-enter (YYYYMMDD):')
			date_begin = input()
	print('Enter the ending date (YYYYMMDD):')
	date_end = input()
	while format_date_end == False:
		if len(date_end) == 8:
			try:
				format_date_end_validation = datetime.datetime.strptime(date_end, '%Y%m%d')
				if format_date_end_validation > format_date_begin_validation:
					format_date_end = True
				else:
					print('The ending date must be after the starting date. Please re-enter (YYYYMMDD)')
					date_end = input()
			except:
				print('The date is invalid. Please re-enter (YYYYMMDD):')
				date_end = input()
		else:
			print('The date is invalid. Please re-enter (YYYYMMDD):')
			date_end = input()
	print('The date range is from ' + date_begin + ' to ' + date_end + '. Enter (Y/y) to confirm.')
	confirmed = input()
	if confirmed in ['Y', 'y']:
		confirmation_date = True
	else:
		format_date_begin = False
		format_date_end = False

print('(The programme is running. A notice with the name of the saved file will appear once the execution finishes.)')

os.chdir(os.getcwd())

market = ak.get_futures_daily(start_date = date_begin, end_date = date_end, market = market_input)

cn_market = pd.DataFrame(market)
cn_market = cn_market.ffill(axis = 0)
cn_market = cn_market.sort_values(by = ['symbol', 'date'])

cn_market.to_csv('cn_future_' + market_input + '_' + date_begin + '_' + date_end + '.csv', index = False)
print('(The file is saved as: cn_future_' + market_input + '_' + date_begin + '_' + date_end + '.csv)')
