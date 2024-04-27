"""
Description: This file creates the country crosswalk.
"""
# %% Load packages
import numpy as np
import pandas as pd
from fuzzywuzzy import process

# %% Define function to fuzzy match (src: https://stackoverflow.com/a/56315491/11952647)
def fuzzy_merge(df_1, df_2, key1, key2, threshold=90, limit=2):
    """
    :param df_1: the left table to join
    :param df_2: the right table to join
    :param key1: key column of the left table
    :param key2: key column of the right table
    :param threshold: how close the matches should be to return a match, based on Levenshtein distance
    :param limit: the amount of matches that will get returned, these are sorted high to low
    :return: dataframe with boths keys and matches
    """
    s = df_2[key2].tolist()

    m = df_1[key1].apply(lambda x: process.extract(x, s, limit=limit))
    df_1['matches'] = m

    m2 = df_1['matches'].apply(lambda x: ', '.join(
        [i[0] for i in x if i[1] >= threshold]))
    df_1['matches'] = m2

    return df_1
# %% Load data
fao = pd.read_csv("data/input/hand/fao_country_crosswalk.csv")
prices = pd.read_csv("data/input/faostat/Prices_E_All_Data_(Normalized).csv",
                     encoding_errors='ignore', usecols=['Area Code', 'Area'])
prices.drop_duplicates(inplace=True)
trade = pd.read_csv("data/input/baci_comtrade/country_codes_V202102.csv",
                    encoding_errors='ignore')
gaez = pd.read_csv("data/input/cds_2016/CountryNamesNumbers.csv")
# %% Match trade data to FAO crosswalk by ISO3 country code
fao['Official name'] = fao['Official name'].map(lambda x: x.lstrip('the '))
df1 = fao.merge(trade, left_on='ISO3',
                      right_on='iso_3digit_alpha', how='outer')
df1['UNI'].fillna(df1['country_code'], inplace=True)
# %% Verbatim match GAEZ on country names
df1 = pd.concat([pd.merge(df1, gaez, left_on='Short name', right_on='country_name_UN', how='left'),
                pd.merge(df1, gaez, left_on='country_name_full', right_on='country_name_UN', how='left')])
df1.fillna('', inplace=True)
# %% Fuzzy match GAEZ on variations of country names
df_short = fuzzy_merge(df1, gaez, 'Short name', 'country_name_UN', threshold=90, limit=1)
df_official = fuzzy_merge(df1, gaez, 'Official name', 'country_name_UN', threshold=90, limit=1)
df_full = fuzzy_merge(df1, gaez, 'country_name_full', 'country_name_UN', threshold=90, limit=1)
df2 = pd.concat([df_short, df_official, df_full])
# %% Fill in GAEZ IDs and clean up
df2['country_name_UN'] = df2[['country_name_UN', 'matches']].apply(lambda x: x[0] if x[0] else x[1], axis=1)
df2 = df2.merge(gaez, on='country_name_UN', how='left')
df2.drop(['cid_x', 'matches'], axis=1, inplace=True)
df2.rename(columns={'cid_y': 'cid'}, inplace=True)
df2.drop_duplicates(inplace=True)
# %% Handle edge cases
df2 = df2.astype({'UNI': 'Int64'})
df2 = df2.astype({'cid': 'Int64'}, errors='ignore')
## British Indian Ocean Territories
df2.loc[df2['UNI'] == 86, 'country_name_UN'] = ''
df2.loc[df2['UNI'] == 86, 'cid'] = 0
## Burma
df2.loc[df2['UNI'] == 104, 'country_name_UN'] = 'Burma'
df2.loc[df2['UNI'] == 104, 'cid'] = 132
## Czech Republic
df2.loc[df2['UNI'] == 203, 'country_name_UN'] = 'Czech Republic'
df2.loc[df2['UNI'] == 203, 'cid'] = 51
## Switzerland
df2.loc[df2['UNI'] == 756, 'country_name_UN'] = 'Switzerland'
df2.loc[df2['UNI'] == 756, 'cid'] = 186
## United States
df2.loc[df2['UNI'].isin([840,842]), 'country_name_UN'] = 'United States'
df2.loc[df2['UNI'].isin([840,842]), 'cid'] = 202
# %% Collapse entries by UN country code
df2 = df2.groupby(['UNI']).max()
df2.reset_index(inplace=True)
# %% Now repeat the process for prices
df2['FAOSTAT'].replace(r'^\s*$', np.nan, regex=True, inplace=True)
df2 = df2.astype({'FAOSTAT': 'Int64'})
prices = prices.astype({'Area Code': 'Int64'})
df3 = pd.merge(df2, prices, left_on='FAOSTAT', right_on='Area Code', how='left')
crosswalk = pd.concat([df3,
                        fuzzy_merge(df3, prices, 'country_name_UN', 'Area', threshold=90, limit=1),
                        fuzzy_merge(df3, prices, 'country_name_abbreviation', 'Area', threshold=90, limit=1)])
crosswalk['Area'].fillna('', inplace=True)
crosswalk['Area'] = crosswalk[['Area', 'matches']].apply(
    lambda x: x[0] if x[0] else x[1], axis=1)
crosswalk = crosswalk.merge(prices, on='Area', how='left')
crosswalk.drop(['Area Code_x', 'matches'], axis=1, inplace=True)
crosswalk.rename(columns={'Area Code_y': 'Area Code'}, inplace=True)
crosswalk.drop_duplicates(inplace=True)
crosswalk.dropna(axis=0, subset=['cid'], how='all', inplace=True)
crosswalk.sort_values(by=['UNI'], inplace=True)
# %% Handling edge cases
## American Samoa
crosswalk.loc[crosswalk['UNI'] == 16, 'Area'] = ''
crosswalk.loc[crosswalk['UNI'] == 16, 'Area Code'] = 0
## British Indian Ocean Territories
crosswalk.loc[crosswalk['UNI'] == 86, 'Area'] = ''
crosswalk.loc[crosswalk['UNI'] == 86, 'Area Code'] = 0
## Democratic Republic of the Congo
crosswalk.loc[crosswalk['UNI'] == 180, 'Area'] = 'Democratic Republic of the Congo'
crosswalk.loc[crosswalk['UNI'] == 180, 'Area Code'] = 250
## Dominica
crosswalk.loc[crosswalk['UNI'] == 212, 'Area'] = 'Dominica'
crosswalk.loc[crosswalk['UNI'] == 212, 'Area Code'] = 55
## Papua New Guinea
crosswalk.loc[crosswalk['UNI'] == 598, 'Area'] = ''
crosswalk.loc[crosswalk['UNI'] == 598, 'Area Code'] = 0
## United States
crosswalk.loc[crosswalk['UNI'].isin([840,842]), 'Area'] = 'United States of America'
crosswalk.loc[crosswalk['UNI'].isin([840,842]), 'Area Code'] = 231
## Drop East Germany and South Sudan
crosswalk.drop(crosswalk[crosswalk['UNI'] == 278].index, inplace=True)
crosswalk.drop(crosswalk[crosswalk['UNI'] == 728].index, inplace=True)
# %% Save to CSV
crosswalk.to_csv('data/intermediate/crosswalks/country_crosswalk.csv', index=False)