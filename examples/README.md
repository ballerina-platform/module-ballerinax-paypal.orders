# Examples

The `ballerinax/paypal.orders` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-paypal.orders/tree/main/examples), covering use cases such as executing a full order lifecycle - creating, updating, confirming, and capturing payments - as well as enriching orders with shipping details and updating tracking information.

1. [**Order lifecycle**](https://github.com/ballerina-platform/module-ballerinax-paypal.orders/tree/main/examples/order-lifecycle): Process a complete PayPal order from creation and updates through confirming and capturing payments.

2. [**Manage shipping**](https://github.com/ballerina-platform/module-ballerinax-paypal.orders/tree/main/examples/manage-shipping): Enrich an order with shipping details, add or update tracking information, and push shipment updates back to PayPal.

## Prerequisites

1. Generate PayPal OAuth2 credentials to authenticate the connector as described in the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-paypal.orders#setup-guide).

2. For each example, create a `Config.toml` file with your PayPal configuration. For instance:

```toml
clientId = "<your-paypal-client-id>"
clientSecret = "<your-paypal-client-secret>"

serviceUrl = "https://api.sandbox.paypal.com/v2/checkout"
tokenUrl = "https://api.sandbox.paypal.com/v1/oauth2/token"
```

## Running an example

Execute the following commands to build an example from the source:

- To build an example:

  ```bash
  bal build
  ```

- To run an example:

  ```bash
  bal run
  ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

- To build all the examples:

  ```bash
  ./build.sh build
  ```

- To run all the examples:

  ```bash
  ./build.sh run
  ```
