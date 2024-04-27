"""
Description: This file cleans the production data from the FAO.
"""

# %% load packages
import pandas as pd
# %% load data
yields_raw = pd.read_csv(
    'data/input/faostat/Production_Crops_Livestock_E_All_Data_(Normalized).csv',
    encoding='ISO-8859-1')
# for some reason most of Sudan was missing, so I need to manually append it
sudan_yields_raw = pd.read_csv(
    'data/input/faostat/fmrsudan_qcl.csv', encoding='ISO-8859-1')
sudan_yields_raw.drop(['ï»¿Domain Code', 'Domain', 'Flag Description'],
                      axis=1, inplace=True)
sudan_yields_raw.rename({'Area Code (FAO)': 'Area Code', 'Item Code (FAO)': 'Item Code'},
                        axis=1, inplace=True)
yields_raw = pd.concat([yields_raw, sudan_yields_raw], axis=0, ignore_index=True)
yields_raw.drop_duplicates(inplace=True)
prodvalue_raw = pd.read_csv(
    'data/input/faostat/Value_of_Production_E_All_Data_(Normalized).csv',
    encoding='ISO-8859-1')
# %%
#--------------------------------- Yields -------------------------------------#
# %% drop unnecessary yields data
yields_raw.drop(yields_raw.filter(regex='^Element').columns, axis=1, inplace=True)
df = yields_raw.loc[yields_raw['Unit'].isin(['hg/ha', 'tonnes'])]
df = df.loc[df['Year'] > 1990]
df = df.loc[df['Area Code'] < 5000]
# %% reshape
yields_full = df.pivot(index=['Area Code', 'Area', 'Item Code', 'Item', 'Year'],
                       columns='Unit',
                       values='Value')
yields_full.reset_index(inplace=True)
yields_full.rename(columns={'hg/ha':'yield_hgperha', 'tonnes':'production_tonnes'}, inplace=True)
yields_full = yields_full.loc[yields_full['Item Code'] <= 850]
# %% export full yields
yields_full.to_csv('data/intermediate/production/yields_full.csv', index=False)
# %% select a baseline year
yields_baseline = yields_full[yields_full['Year'] == 2009]
# %% export baseline yields
yields_baseline.to_csv('data/intermediate/production/yields_baseline.csv', index=False)
# %%
#----------------------------- Area harvested ---------------------------------#
# %% drop unnecessary yields data
df = yields_raw.loc[yields_raw['Unit'].isin(['ha'])]
df = df.loc[df['Year'] > 1990]
df = df.loc[df['Area Code'] < 5000]
# %% reshape
harvestarea_full = df.pivot(index=['Area Code', 'Area', 'Item Code', 'Item', 'Year'],
                       columns='Unit',
                       values='Value')
harvestarea_full.reset_index(inplace=True)
harvestarea_full.rename(columns={'ha':'harvestarea_ha'}, inplace=True)
harvestarea_full = harvestarea_full.loc[harvestarea_full['Item Code'] <= 850]
# %% export full harvested area
harvestarea_full.to_csv('data/intermediate/production/harvestarea_full.csv', index=False)
# %% select a baseline year
harvestarea_baseline = harvestarea_full[harvestarea_full['Year'] == 2009]
# %% export baseline harvested area
harvestarea_baseline.to_csv('data/intermediate/production/harvestarea_baseline.csv', index=False)
# %%
#---------------------------------- Value -------------------------------------#
# %% drop unnecessary value data
# df = prodvalue_raw[prodvalue_raw['Element Code'].isin([57,58])] # USD
df = prodvalue_raw.loc[prodvalue_raw['Year'] > 1990]
df = df.loc[df['Area Code'] < 5000]
# %% reshape
prodvalue_full = df.pivot(index=['Area Code', 'Area', 'Item Code', 'Item', 'Year'],
                          columns='Element',
                          values='Value')
prodvalue_full.reset_index(inplace=True)
prodvalue_full = prodvalue_full.loc[prodvalue_full['Item Code'] <= 850]
prodvalue_full.rename(columns={'Gross Production Value (constant 2014-2016 thousand I$)': 'gross_production_value_constantint',
                               'Gross Production Value (constant 2014-2016 thousand SLC)': 'gross_production_value_constantslc',
                               'Gross Production Value (current thousand SLC)': 'gross_production_value_currentslc',
                               'Gross Production Value (constant 2014-2016 thousand US$)': 'gross_production_value_constantusd',
                               'Gross Production Value (current thousand US$)': 'gross_production_value_currentusd'},
                      inplace=True)
# %% export full values
prodvalue_full.to_csv('data/intermediate/production/prodvalue_full.csv', index=False)
# %% select a baseline year
prodvalue_baseline = prodvalue_full.loc[prodvalue_full['Year'] == 2009]
# %% export baseline values
prodvalue_baseline.to_csv('data/intermediate/production/prodvalue_baseline.csv', index=False)
