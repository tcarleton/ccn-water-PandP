"""
Description: This file cleans the trade data from BACI/COMTRADE.
"""

# %%
import pandas as pd
# %%
products = pd.read_csv('data/input/baci_comtrade/product_codes_HS07_V202102.csv', sep=',', dtype={'code':str})
country_names = pd.read_csv('data/input/baci_comtrade/country_codes_V202102.csv', sep=',', encoding = "ISO-8859-1")
df = pd.read_csv('data/input/baci_comtrade/BACI_HS07_Y2009_V202102.csv', sep=',', dtype={'k':str})
# %%
df = df.merge(country_names[['country_code', 'iso_3digit_alpha']],
              how='left', left_on='i', right_on='country_code')
df.rename(columns={'iso_3digit_alpha':'i_iso3'}, inplace=True)
df.drop('country_code', axis=1, inplace=True)
# %%
df = df.merge(country_names[['country_code', 'iso_3digit_alpha']],
              how='left', left_on='j', right_on='country_code')
df.rename(columns={'iso_3digit_alpha':'j_iso3'}, inplace=True)
df.drop('country_code', axis=1, inplace=True)
# %%
df = df.merge(products, how='left', left_on='k', right_on='code')
df.drop('code', axis=1, inplace=True)
# %% correct for different resolution of trade data
df.loc[df['i'] == 251, 'i'] = 250  # France & Monaco combined = France
df.loc[df['j'] == 251, 'j'] = 250  # France & Monaco combined = France
df.loc[df['i'] == 381, 'i'] = 380  # Italy
df.loc[df['j'] == 381, 'j'] = 380  # Italy
df.loc[df['i'] == 579, 'i'] = 578  # Norway
df.loc[df['j'] == 579, 'j'] = 578  # Norway
df.loc[df['i'] == 699, 'i'] = 356  # India
df.loc[df['j'] == 699, 'j'] = 356  # India
df.loc[df['i'] == 736, 'i'] = 729  # Fmr. Sudan
df.loc[df['j'] == 736, 'j'] = 729  # Fmr. Sudan
df.loc[df['i'] == 757, 'i'] = 756  # Switzerland + Liechtenstein = Switzerland
df.loc[df['j'] == 757, 'j'] = 756  # Switzerland + Liechtenstein = Switzerland
df.loc[df['i'] == 842, 'i'] = 840  # USA + Minor Islands = USA
df.loc[df['j'] == 842, 'j'] = 840  # USA + Minor Islands = USA
# %%
df.to_csv('data/intermediate/trade/trade_baseline.csv', index=False)
