"""
Description: This file creates the crop crosswalk.
"""

# %% Load packages
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
base = pd.read_csv('data/input/hand/FCL_HS_mappings_2020-01-07.csv') # official FAOSTAT Commodity List to HS code crosswalk
hsnames = pd.read_csv('data/input/baci_comtrade/product_codes_HS07_V202102.csv')
fao = pd.read_csv("data/input/faostat/Prices_E_All_Data_(Normalized).csv",
                     encoding_errors='ignore', usecols=['Item Code', 'Item'])
fao.drop_duplicates(inplace=True)
gaez = pd.read_csv('data/input/cds_2016/crop_names_numbers_codes.csv')
aginc = pd.read_csv('data/input/nra/AgIncentivesNRP.csv', usecols=['ProductCode', 'ProductName'])
dai = pd.read_excel(
    'data/input/nra/UpdatedDistortions_to_AgriculturalIncentives_database_0613.xls',
    sheet_name='Data', header=0, usecols=['prod2'])
dai.drop_duplicates(inplace=True)
# %% more work on DAI
aginc.drop_duplicates(inplace=True)
aginc = aginc[aginc['ProductCode'].str.startswith('c', na=False)]
aginc['FCL code'] = aginc['ProductCode'].map(lambda x: x.lstrip('c'))
aginc = aginc[aginc['FCL code'].str.isnumeric()]
aginc = aginc.astype({'FCL code': int})
# %% Complete FAO-HS crosswalk
df = pd.merge(base, hsnames, how='left', left_on='HS code', right_on='code')
df = pd.merge(df, fao, how='left', left_on='FCL code', right_on='Item Code')
df.dropna(axis=0, subset=['Item Code'], how='all', inplace=True)
df = df.loc[df['FCL code'] < 850] # drop animal products
# %% Merge in AgIncentives
df = pd.merge(df, aginc, how='left', on='FCL code')
# %% Fuzzy merge in GAEZ: works well as first pass, but overloads "beans"
crosswalk = fuzzy_merge(df, gaez, 'FCL label', 'crop_name_gaez', threshold=90, limit=1)
crosswalk.loc[crosswalk['FCL label'] == 'Oats', 'matches'] = 'Oat'
crosswalk.loc[crosswalk['FCL label'] == 'Potatoes', 'matches'] = 'White Potato'
crosswalk.loc[crosswalk['FCL label'] == 'Yautia (Cocoyam)', 'matches'] = 'Yam and Cocoyam'
crosswalk.loc[crosswalk['FCL label'] == 'Taro (Cocoyam)', 'matches'] = 'Yam and Cocoyam'
crosswalk.loc[crosswalk['FCL label'] == 'Yams', 'matches'] = 'Yam and Cocoyam'
crosswalk.loc[crosswalk['FCL label'] == 'Broad beans, dry', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'Chick-peas, dry', 'matches'] = 'Chickpea'
crosswalk.loc[crosswalk['FCL label'] == 'Peas, dry', 'matches'] = 'Dry Pea'
crosswalk.loc[crosswalk['FCL label'] == 'Bambara beans', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == '[Oil palm fruit]', 'matches'] = 'Oilpalm'
crosswalk.loc[crosswalk['FCL label'] == 'Palm kernels', 'matches'] = 'Oilpalm'
crosswalk.loc[crosswalk['FCL label'] == 'Oil of palm', 'matches'] = 'Oilpalm'
crosswalk.loc[crosswalk['FCL label'] == 'Castor Beans', 'matches'] = ''
# crosswalk.loc[crosswalk['FCL label'] == '[Seed Cotton]', 'matches'] = ''
# crosswalk.loc[crosswalk['FCL label'] == 'Cotton Lint', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'Onions, shallots (green)', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'Beans, green', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'Broad Beans, Green', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'String Beans', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'Green Corn (Maize)', 'matches'] = ''
crosswalk.loc[crosswalk['FCL label'] == 'Oranges', 'matches'] = 'Citrus'
crosswalk.loc[crosswalk['FCL label'] == 'Tangerines, mandarins, clementines, satsumas', 'matches'] = 'Citrus'
crosswalk.loc[crosswalk['FCL label'] == 'Lemons and limes', 'matches'] = 'Citrus'
crosswalk.loc[crosswalk['FCL label'] == 'Grapefruit and pomelo', 'matches'] = 'Citrus'
crosswalk.loc[crosswalk['FCL label'] == 'Cocoa beans', 'matches'] = 'Cocoa'
crosswalk.loc[crosswalk['FCL label'] == 'Mate', 'matches'] = 'Tea'
# %% Merge in GAEZ crop numbers
crosswalk = pd.merge(crosswalk, gaez, how='left', left_on='matches', right_on='crop_name_gaez')
crosswalk.drop(['matches'], axis=1, inplace=True)
# %% Fuzzy merge in DAI
dai['prod2'] = dai['prod2'].astype(str)
crosswalk['FCL label'] = crosswalk['FCL label'].astype(str)
crosswalk = fuzzy_merge(crosswalk, dai, 'FCL label', 'prod2', threshold=90, limit=1)
crosswalk.loc[crosswalk['FCL label']=='Oats', 'matches'] = 'oat'
crosswalk.loc[crosswalk['FCL label'] == 'Potatoes', 'matches'] = 'potato'
crosswalk.loc[crosswalk['FCL label'] == 'Sweet potatoes', 'matches'] = 'sweetpotato'
crosswalk.loc[crosswalk['FCL label'] == 'Yams', 'matches'] = 'yam'
crosswalk.loc[crosswalk['FCL label'] == 'Chick-peas, dry', 'matches'] = 'chickpea'
crosswalk.loc[crosswalk['FCL label'] == 'Carrot', 'matches'] = 'otherroots&tubers'
crosswalk.loc[crosswalk['FCL label'] == 'Grapefruit and pomelo', 'matches'] = 'grapefruit'
crosswalk.loc[crosswalk['FCL label'] == '[Oil palm fruit]', 'matches'] = 'palmoil'
crosswalk.loc[crosswalk['FCL label'] == 'Palm kernels', 'matches'] = 'palmoil'
crosswalk.loc[crosswalk['FCL label'] == 'Oil of palm', 'matches'] = 'palmoil'
crosswalk.loc[crosswalk['FCL label'] == 'Mate', 'matches'] = 'tea'
crosswalk.loc[crosswalk['FCL label'] == 'Buckwheat', 'matches'] = 'othercrops'
crosswalk.loc[crosswalk['FCL label'] == 'Flax fibre and tow', 'matches'] = 'othercrops'
crosswalk.rename(columns={'matches': 'prod2'}, inplace=True)
# %% Save crosswalk to CSV
crosswalk.to_csv('data/intermediate/crosswalks/crop_crosswalk.csv', index=False)