## Overview

[PayPal](https://www.paypal.com/) is a global online payment platform enabling individuals and businesses to securely send and receive money, process transactions, and access merchant services across multiple currencies.

The `ballerinax/paypal.orders` package provides a Ballerina connector for interacting with the [PayPal Orders API v2](https://developer.paypal.com/docs/api/orders/v2/), allowing you to create, capture, authorize, and manage orders in your Ballerina applications.

## Setup guide

To use the PayPal Orders connector, you must have access to a [PayPal Developer account](https://developer.paypal.com/).

### Step 1: Create a business account

1. Open the [PayPal Developer Dashboard](https://developer.paypal.com/dashboard).

2. Click on "Sandbox Accounts" under "Testing Tools".

   ![Sandbox accounts](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-paypal.orders/main/docs/setup/resources/sandbox-accounts.png)

3. Create a Business account

   > Note: Some PayPal options and features may vary by region or country; check availability before creating an account.

   ![Create business account](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-paypal.orders/main/docs/setup/resources/create-account.png)

### Step 2: Create a REST API app

1. Navigate to the "Apps and Credentials" tab and create a new merchant app.

   Provide a name for the application and select the Business account you created earlier.

   ![Create app](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-paypal.orders/main/docs/setup/resources/create-app.png)

### Step 3: Obtain Client ID and Client Secret

1. After creating your new app, you will see your **Client ID** and **Client Secret**. Make sure to copy and securely store these credentials.

   ![Credentials](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-paypal.orders/main/docs/setup/resources/get-credentials.png)

## Quickstart

To use the `paypal.orders` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `paypal.orders` module.

```ballerina
import ballerinax/paypal.orders as paypal;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained credentials in the above steps as follows:

```toml
clientId = "<test-client-id>"
clientSecret = "<test-client-secret>"

serviceUrl = "<paypal-service-url>"
tokenUrl = "<paypal-token-url>"
```

2. Create a `paypal:ConnectionConfig` with the obtained credentials and initialize the connector with it.

```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;

configurable string serviceUrl = ?;
configurable string tokenUrl = ?;
```

```ballerina
final paypal:Client paypal = check new ({
    auth: {
        clientId,
        clientSecret,
        tokenUrl
    }
}, serviceUrl);
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create an order

```ballerina
public function main() returns error? {
    paypal:Order response = check paypal->/orders.post({
        intent: "CAPTURE",
        purchase_units: [{
                amount: {
                    currency_code: "USD",
                    value: "100.00"
                }
            }]
    });
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `PayPal Orders` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-paypal.orders/tree/main/examples/), covering the following use cases:

1. [**Order lifecycle**](https://github.com/ballerina-platform/module-ballerinax-paypal.orders/tree/main/examples/order-lifecycle): Process a complete PayPal order from creation and updates through confirming and capturing payments.

2. [**Manage shipping**](https://github.com/ballerina-platform/module-ballerinax-paypal.orders/tree/main/examples/manage-shipping): Enrich an order with shipping details, add or update tracking information, and push shipment updates back to PayPal.
