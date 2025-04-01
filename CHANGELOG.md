# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## 6.0.0

### Changed

- **Breaking change**: Change StatsdMiddleware metric type from timing to
  distribution. Prior to 6.0.0, if you set the metric name to
  `my_service.response.time`, then in Datadog you ended up with metrics
  `my_service.response.time.avg`, `my_service.response.time.95_percentile`,
  `my_service.response.time.count`. Now, only one metric with name
   `my_service.response.time` of type distribution is sent.
