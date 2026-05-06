# Debug Logging Documentation

## Overview

Both `aggregator.py` and `battery.py` now include comprehensive debug logging to help with troubleshooting, monitoring, and development.

## Logging Configuration

### Aggregator Logging
The aggregator configures logging with:
- **File Output**: `aggregator.log`
- **Console Output**: Standard output
- **Log Level**: DEBUG (configurable)
- **Format**: `%(asctime)s - %(name)s - %(levelname)s - %(message)s`

### Log Levels Used
- **INFO**: Normal operations, API requests, successful operations
- **DEBUG**: Detailed information, TLS configuration, database queries
- **WARNING**: Non-critical issues, failed operations
- **ERROR**: Errors, exceptions, connection failures

## What Gets Logged

### Aggregator (`aggregator.py`)
- **Startup**: Server initialization, environment variables, MongoDB connection
- **API Requests**: All incoming HTTP requests with endpoints and parameters
- **Database Operations**: Battery creation, updates, queries
- **TLS Configuration**: Certificate paths, SSL settings (sensitive data masked)
- **Battery Operations**: Charge/discharge/idle commands with results
- **Connection Tests**: TLS connection test results
- **Errors**: All exceptions with stack traces

### Battery EMS (`battery.py`)
- **Initialization**: Battery instance creation, URL construction
- **TLS Setup**: SSL context creation, certificate configuration
- **HTTP Requests**: All GET/POST requests to EMS devices
- **Connection Tests**: Connection health checks
- **EMS Operations**: All battery control operations
- **Errors**: Network failures, TLS errors, timeouts

## Log File Examples

### Successful Battery Creation
```
2025-10-23 10:15:23,456 - __main__ - INFO - POST /battery - Adding new battery
2025-10-23 10:15:23,457 - __main__ - DEBUG - Received battery data: {'name': 'Tesla Battery', 'battery_id': 'BATT001', ...}
2025-10-23 10:15:23,458 - __main__ - DEBUG - Creating BatteryEMS for BATT001 - TLS: True, EMS: ems.example.com:9001
2025-10-23 10:15:23,459 - battery - INFO - Initializing BatteryEMS for BATT001 - EMS URL: https://ems.example.com:9001, TLS: True
2025-10-23 10:15:23,460 - battery - DEBUG - Configuring TLS session for battery BATT001
```

### TLS Configuration Logging
```
2025-10-23 10:15:23,461 - battery - DEBUG - SSL verification set to: True
2025-10-23 10:15:23,462 - battery - DEBUG - Using client certificate: /certs/client.crt with key: /certs/client.key
2025-10-23 10:15:23,463 - battery - DEBUG - Using CA certificate file: /certs/ca.crt
2025-10-23 10:15:23,464 - battery - DEBUG - Creating custom SSL context
2025-10-23 10:15:23,465 - battery - DEBUG - Set minimum TLS version to 1.2
```

### Battery Operations
```
2025-10-23 10:16:15,123 - __main__ - INFO - POST /SA001/Charge - Charging batteries in service area
2025-10-23 10:16:15,124 - __main__ - DEBUG - Found 3 batteries in service area SA001
2025-10-23 10:16:15,125 - __main__ - DEBUG - Attempting to charge battery BATT001
2025-10-23 10:16:15,126 - battery - INFO - Setting charge/discharge rate for battery BATT001 to 100
2025-10-23 10:16:15,127 - battery - DEBUG - POST request to EMS for battery BATT001: https://ems.example.com:9001/api/v1/write/load1.setChargeDischargeRate/100 with value: 100
```

### Error Logging
```
2025-10-23 10:17:30,789 - battery - ERROR - POST request failed for battery BATT001 to https://ems.example.com:9001/api/v1/write/load1.setChargeDischargeRate/100: Connection timeout
2025-10-23 10:17:30,790 - __main__ - ERROR - Error charging battery BATT001: An error occurred while posting to https://ems.example.com:9001/api/v1/write/load1.setChargeDischargeRate/100: Connection timeout
```

## Testing Debug Logging

Use the provided test script:
```bash
python test_debug_logging.py
```

This will:
1. Create various BatteryEMS instances with different configurations
2. Demonstrate TLS setup logging
3. Show connection test logging
4. Generate a `test_debug.log` file with all debug output

## Log File Management

### Production Recommendations
1. **Log Rotation**: Implement log rotation to prevent large files
2. **Log Level**: Set to INFO or WARNING in production
3. **Sensitive Data**: Certificate contents are never logged (only paths)
4. **Performance**: Debug logging may impact performance under high load

### Environment Variables for Log Control
Add these to your `.env` file:
```bash
# Logging configuration
LOG_LEVEL=INFO
LOG_FILE=aggregator.log
ENABLE_DEBUG_LOGGING=false
```

## Security Considerations

- **Certificate Paths**: Only file paths are logged, not certificate contents
- **Passwords**: MongoDB passwords are masked in logs
- **URLs**: Full URLs are logged but can contain sensitive hostnames
- **Error Messages**: May contain sensitive system information

## Troubleshooting with Logs

### Common Issues to Look For

1. **TLS Certificate Problems**:
   ```
   ERROR - Failed to configure TLS session: [SSL: CERTIFICATE_VERIFY_FAILED]
   ```

2. **Connection Timeouts**:
   ```
   ERROR - POST request failed: Connection timeout
   ```

3. **Authentication Issues**:
   ```
   ERROR - GET request failed: 401 Client Error: Unauthorized
   ```

4. **MongoDB Connection Issues**:
   ```
   ERROR - Failed to connect to MongoDB: ServerSelectionTimeoutError
   ```

### Log Analysis Tips

1. **Filter by Battery ID**: Search logs for specific battery operations
2. **Follow Request Flow**: Trace API requests through to EMS calls
3. **Monitor TLS Setup**: Check certificate loading and SSL context creation
4. **Watch for Patterns**: Identify recurring connection issues

This comprehensive logging system provides full visibility into the aggregator's operation and makes debugging much easier.