import requests
mdx_key = 'FA8F60A1A6F5D9254DD8E1D3566E7C30'
# replace with your KEY!
mdx_url = ('https://mdx.meteotest.ch/api_v1?key={key}&service=solarforecast'
           '&action=getforecast&format=json&name=StrategyWeatherDataForecasts'.format(key=mdx_key))

r = requests.get(mdx_url)
result = r.json()

if r.status_code == 200:
  print("forecast data:")
  print(result)
else:
  print("An error occurred:")
  # let's check what the problem is...
  print(result)