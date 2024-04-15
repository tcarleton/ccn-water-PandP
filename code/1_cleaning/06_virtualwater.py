"""
Description: This file creates the virtual water flows estimates.
"""

# %% load packages
import pandas as pd
import re
# %% load and clean country crosswalk
cross_country = pd.read_csv('data/intermediate/crosswalks/country_crosswalk.csv')
cross_country = cross_country[['UNI', 'Short name', 'Official name', 'ISO3', 'ISO2', 'UNDP', 'FAOSTAT',
                 'GAUL', 'country_code', 'country_name_abbreviation',
                 'country_name_full', 'iso_2digit_alpha', 'iso_3digit_alpha',
                 'country_name_UN', 'cid', 'Area', 'Area Code']]
cross_country.reset_index(drop=True, inplace=True)
cross_country.reset_index(drop=False, inplace=True)
cross_country.rename(columns={'index':'countryid'}, inplace=True)
cross_country['countryid'] = cross_country['countryid'] + 1
# %% load country-specific water intensities
base_footprint = pd.read_excel('data/input/crop_water_footprint/Report47-Appendix-II.xlsx',
                               sheet_name='App-II-WF_perTon',
                               skiprows=3,
                               index_col=[0,1,2,3,4,5,6,7,8],
                               header=[0,1],
                               skipfooter=3)
# %% prep country-specific water intensities
footprint = base_footprint.iloc[:, base_footprint.columns.get_level_values(1)=='CNTRY-average']
footprint = footprint.droplevel(1, axis=1)
footprint = footprint.stack('Country >>>')
footprint = footprint.unstack('WF type')
footprint.reset_index(inplace=True)
footprint.rename_axis(None, axis=1, inplace=True)
footprint = footprint.loc[:, ['Product code (FAOSTAT)', 'Product code (HS)',
                        'Product description (HS)','Country >>>',
                        'Blue', 'Green', 'Grey']]
footprint.rename(columns={'Product code (FAOSTAT)': 'Item Code',
                          'Product code (HS)': 'k',
                          'Product description (HS)': 'description',
                          'Country >>>': 'country_name_full',
                          'Blue': 'blue',
                          'Green': 'green',
                          'Grey': 'grey'}, inplace=True)
footprint['k'] = footprint['k'].map(lambda k: re.sub(r'[^0-9]', '', k).ljust(6, '0'))
footprint.replace('100110100190', '100110', inplace=True)
# %% merge in better country IDs
namematch = {'Bahamas, The': 'Bahamas',
             'Belgium': 'Belgium-Luxembourg',
             'Bolivia': 'Plurinational State of Bolivia',
             'Bosnia and Herzegovina': 'Bosnia Herzegovina',
             'Brunei': 'Brunei Darussalam',
             'Cape Verde': 'Cabo Verde',
             'Congo, Democratic Republic of': 'Democratic Republic of the Congo',
             'Congo, Democratic Republic of the': 'Democratic Republic of the Congo',
             'Czech Republic': 'Czechia',
             'France': 'France, Monaco',
             'Gambia, The': 'Gambia',
             'Iran, Islamic Republic of': 'Iran',
             "Korea, Democratic People's Republic of": "Democratic People's Republic of Korea",
             'Korea, Republic of': 'Republic of Korea',
             "Lao People's Democratic Republic": "Lao People's Dem. Rep.",
             'Laos': "Lao People's Dem. Rep.",
             'Libyan Arab Jamahiriya': 'Libya',
             'Macedonia , The Former Yugoslav Republic of': 'The Former Yugoslav Republic of Macedonia',
             'Moldova': 'Republic of Moldova',
             'Norway': 'Norway, Svalbard and Jan Mayen',
             'Russia': 'Russian Federation',
             'Switzerland': 'Switzerland, Liechtenstein',
             'Syrian Arab Republic': 'Syria',
             'Tanzania': 'United Republic of Tanzania',
             'Tanzania, United Republic of': 'United Republic of Tanzania',
             'United States of America': 'USA, Puerto Rico and US Virgin Islands',
             'Venezuela, Bolivarian Republic of': 'Venezuela',
             'Vietnam': 'Viet Nam'
            }
footprint.replace(namematch, inplace=True)
footprint = pd.merge(cross_country[['country_name_full', 'countryid']], footprint,
                     how='right', on='country_name_full')
# the circumflex on the "o" is always a pain
footprint.loc[footprint['country_name_full'] == "Côte d'Ivoire", 'countryid'] = 95
# not sure why the next two don't match automatically
footprint.loc[footprint['country_name_full'] == "Ethiopia", 'countryid'] = 60
footprint.loc[footprint['country_name_full'] == "South Africa", 'countryid'] = 175
# MH list Serbia and Montenegro together, but the trade data has them separate
footprint.loc[footprint['country_name_full'] == "Serbia and Montenegro", 'countryid'] = 123 # Montenegro
serbian_footprint = footprint.loc[footprint['country_name_full'] == "Serbia and Montenegro"].copy()
serbian_footprint['countryid'] = 167
footprint = pd.concat([footprint, serbian_footprint], ignore_index=True)
# rename and drop nulls
footprint.rename(columns={'countryid': 'i'}, inplace=True)
footprint = footprint.loc[~footprint['i'].isnull()]
footprint.fillna(0, inplace=True)
# %% compute totals
footprint['tot_bluegreen'] = footprint['blue'] + footprint['green']
footprint['tot_withgrey'] = footprint['tot_bluegreen'] + footprint['grey']
# %% load trade
base_trade = pd.read_csv('data/intermediate/trade/trade_baseline_filled.csv',
                         low_memory=False, dtype={'k': str})
base_trade['k'] = base_trade['k'].map(lambda k: k.rjust(6, '0'))
base_trade.replace('100190', '100110', inplace=True) # since MH have 100110 and 100190 listed jointly
# %% prep trade
trade = pd.merge(cross_country[['iso_3digit_alpha', 'countryid']], base_trade,
                 how='left', left_on='iso_3digit_alpha', right_on='j_iso3')
trade = pd.merge(cross_country[['iso_3digit_alpha', 'countryid']], trade,
                 how='left', left_on='iso_3digit_alpha', right_on='i_iso3')
trade['i'] = trade['countryid_x']
trade['j'] = trade['countryid_y']
trade.drop(trade.filter(regex='^iso_3digit_alpha').columns, axis=1, inplace=True)
trade.drop(trade.filter(regex='^countryid').columns, axis=1, inplace=True)
trade.drop(columns=['t','j'], inplace=True)
# %% merge and sort
df = pd.merge(trade, footprint[['i','k','tot_bluegreen','tot_withgrey']], how='inner', on=['i','k'])
df.sort_values(by=['i_iso3','k','j_iso3'], inplace=True)
df = df[['i_iso3','k','j_iso3','tot_bluegreen','tot_withgrey','q','v']]
# %% just compute it here!
df['virtualwater_bluegreen'] = df['tot_bluegreen'] * df['q']
df['virtualwater_withgrey'] = df['tot_withgrey'] * df['q']
df.to_csv('data/intermediate/trade/virtualwater_baseline.csv', index=False)
