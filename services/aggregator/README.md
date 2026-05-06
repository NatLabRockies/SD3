# Aggregator API

## Overview

The **Aggregator** API is a Flask-based web application designed to manage battery data stored in a MongoDB database. The application allows users to perform various CRUD operations on battery data, as well as manage charging and discharging of batteries in specific service areas using an Energy Management System (EMS).

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [Usage](#usage)
- [Debug Logging](#debug-logging)
- [License](#license)

## Features

- Retrieve all battery information.
- Retrieve battery information by battery ID.
- Add new battery records.
- Update existing battery records.
- Delete battery records.
- Charge and discharge batteries in specified service areas.
- Retrieve API version information.

## Requirements

- Python 3.x
- Flask
- Flask-PyMongo
- MongoDB
- `battery` module (must contain a `BatteryEMS` class for EMS control)

## Installation

1. Clone this repository:

    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2. Install dependencies:

    ```bash
    pip install -r requirements.txt
    ```

3. Set up and configure MongoDB.

4. Run the app:

    ```bash
    python aggregator.py
    ```

## Environment Variables

Before running the application, you need to configure the following environment variables:

| Variable         | Description                        |
|------------------|------------------------------------|
| `MONGO_USERNAME`  | MongoDB username                   |
| `MONGO_PASSWORD`  | MongoDB password                   |
| `MONGO_DATABASE`  | Name of the MongoDB database       |
| `MONGO_HOSTNAME`  | MongoDB server hostname            |
| `MONGO_PORT`      | MongoDB port number                |

You can set them in your shell or within a `.env` file for easier management.

## API Endpoints

### General Endpoints

- **`GET /`**  
  Returns the API name and version.

- **`GET /version`**  
  Returns the API version information.

### Battery Management

- **`GET /batteries`**  
  Returns information about all batteries in the database.

- **`GET /battery/<id>`**  
  Returns information about a specific battery by its `battery_id`.

- **`POST /battery`**  
  Adds a new battery to the database.  
  **Request Body:**  
  ```json
  {
    "name": "Battery Name",
    "description": "Description",
    "battery_id": "unique-battery-id",
    "service_area_id": "service-area-id",
    "ems_ipaddress": "EMS IP Address"
  }


### Service Area Management

- **`POST /<ServiceAreaID>/Charge`**  
POST /<ServiceAreaID>/Charge
Charges all batteries in the specified service area.

- **`POST /<ServiceAreaID>/Discharge`**  
Discharges all batteries in the specified service area.

### Running docker compose

Docker compose has mongo and the flask app. To run:   
`docker compose up -d`

To reach the flask api, the url will be http://localhost:8080

## Debug Logging

For debug logging setup and usage details, see [DEBUG_LOGGING.md](DEBUG_LOGGING.md).

## License

This project is licensed under the terms described in [LICENSE.txt](LICENSE.txt).
