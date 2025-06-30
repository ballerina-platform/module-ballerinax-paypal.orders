# Running Tests

## Prerequisites

- OAuth2 credentials (Client ID & Secret) from your PayPal Developer account.

## Test Environments

There are two test environments for the PayPal Orders connector tests:

| Test Group   | Environment                          |
| ------------ | ------------------------------------ |
| `mock_tests` | Mock server for PayPal API (default) |
| `live_tests` | PayPal Sandbox API                   |

## Running Tests with the Mock Server

### Configure the `Config.toml` file

Create a `Config.toml` file in the `/tests` directory with the following content:

```toml
isLiveServer = false
```

Then, run the following command to run the tests:

```bash
./gradlew clean test
```

## Running Tests with the PayPal Sandbox API

### Configure the `Config.toml` file

Create a `Config.toml` file in the `/tests` directory with the following content:

```toml
isLiveServer = true

clientId = "<your-paypal-client-id>"
clientSecret = "<your-paypal-client-secret>"
```

Then, run the following command to run the tests:

```bash
./gradlew clean test
```

## Running Specific Groups or Test Cases

To run only certain test groups or individual test cases, pass the -Pgroups property:

```bash
./gradlew clean test -Pgroups=<comma-separated-groups-or-test-cases>
```

For example, to run only the mock tests:

```bash
./gradlew clean test -Pgroups=mock_tests
```