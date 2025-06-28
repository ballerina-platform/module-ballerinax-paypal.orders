## Manage shipping

This use case demonstrates how the PayPal Orders connector can be used to manage shipping tracking information for an order: adding initial tracking details and updating them as shipment status changes.

## Prerequisites

### 1. Setup PayPal developer account

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

This example expects two command-line arguments in the following order:

1. **Order ID**: the ID of the existing order

2. **Capture ID**: the payment capture ID associated with that order

Run the example like this (replace with your own IDs):

```bash
bal run -- <YOUR_ORDER_ID> <YOUR_CAPTURE_ID>
```

For instance:

```bash
bal run -- 1ML724352L2834450 5WA42902XN7717639
```