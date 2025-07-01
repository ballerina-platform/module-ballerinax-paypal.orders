# Running tests

## Prerequisites

- OAuth2 credentials (Client ID & Secret) from your PayPal Developer account.

## Test environments

There are two test environments for the PayPal Orders connector tests:

| Test Group   | Environment                          |
| ------------ | ------------------------------------ |
| `mock_tests` | Mock server for PayPal API (default) |
| `live_tests` | PayPal Sandbox API                   |

## Running tests with the mock server

### Configure the `Config.toml` file

Create a `Config.toml` file in the `/tests` directory with the following content:

```toml
isLiveServer = false
```

Then, run the following command to run the tests:

```bash
./gradlew clean test
```

## Running tests with the PayPal sandbox API

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

## Running specific groups or test cases

To run only certain test groups or individual test cases, pass the -Pgroups property:

```bash
./gradlew clean test -Pgroups=<comma-separated-groups-or-test-cases>
```

For example, to run only the mock tests:

```bash
./gradlew clean test -Pgroups=mock_tests
```
