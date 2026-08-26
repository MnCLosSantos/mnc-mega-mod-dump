-- Creating table for insured vehicles
CREATE TABLE IF NOT EXISTS insured_vehicles (
    plate VARCHAR(10) PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    playerName VARCHAR(100) NOT NULL,
    modTier INT NOT NULL,
    isBusiness BOOLEAN NOT NULL,
    startDate VARCHAR(10) NOT NULL,
    endDate VARCHAR(10) NOT NULL,
    category VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    color1 VARCHAR(50),
    color2 VARCHAR(50),
    insuranceCompany VARCHAR(10)
);

-- Creating table for registered vehicles
CREATE TABLE IF NOT EXISTS registered_vehicles (
    plate VARCHAR(10) PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    playerName VARCHAR(100) NOT NULL,
    registrationDate VARCHAR(10) NOT NULL,
    category VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    color1 VARCHAR(50),
    color2 VARCHAR(50)
);

-- Creating table for inspected vehicles
CREATE TABLE IF NOT EXISTS inspected_vehicles (
    plate VARCHAR(10) PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    playerName VARCHAR(100) NOT NULL,
    inspectionDate VARCHAR(10) NOT NULL,
    category VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    color1 VARCHAR(50),
    color2 VARCHAR(50)
);