# laptop-temp-batt

A simple bash script to script to log the current temperature and battery charge of a laptop, for telemetry

Not sophisticated in its interrogation of /sys/class at the moment.

I'm parsing the results with Telegraf, for InfluxDB. I'll include more once I get a Grafana dashboard up.

I also want to look at alerting on trip types (in Grafana directly, I think).
