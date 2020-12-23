# Configuring Telegraf

Note that if you're already sending data to InfluxDB from this host, you'll need to make sure that any global tags are still appropriate. You'll also probably want to exclude this data from any other database that you're writing to. Multiple databases are supported by including your output plugin in double square braces, and, as one option, including a *namedrop* attribute as follows:

```
#...
[[outputs.influxdb]]
  urls = [ "http://${INFLUXDB_HOST:8086" ] # required
  database = "default_db" # required
  # Drop temp_batt data
  namedrop = ["temp_batt*"]
#...
```
