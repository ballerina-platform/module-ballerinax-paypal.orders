## Order lifecycle

This use case demonstrates how the PayPal Orders connector can be used to process an order from creation through updates, payment authorization, and capture.

## Prerequisites

### 1. Setup a PayPal developer account

Refer to the [Setup guide](https://central.ballerina.io/ballerinax/paypal.orders/latest#setup-guide) to obtain necessary credentials (Client ID and Client Secret).

### 2. Configuration

Create a `Config.toml` file in the example's root directory and add your PayPal credentials related configurations as follows:

```toml
clientId = "<your-paypal-client-id>"
clientSecret = "<your-paypal-client-secret>"

serviceUrl = "https://api.sandbox.paypal.com/v2/checkout"
tokenUrl = "https://api.sandbox.paypal.com/v1/oauth2/token"
```

## Run the example

Execute the following command to run the example:

```bash
bal run
```