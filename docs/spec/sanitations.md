_Author_: Sithija Nelusha (@snelusha)
_Created_: 18 June 2025
_Updated_: 18 June 2025
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Paypal Orders.
The OpenAPI specification is obtained from [PayPal’s official GitHub](https://github.com/paypal/paypal-rest-api-specifications/blob/main/openapi/checkout_orders_v2.json).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

## 1. Update server URLs

**Location**: `servers`

**Original**:

```json
"servers": [
  {
    "url": "https://api-m.sandbox.paypal.com",
    "description": "PayPal Sandbox Environment"
  },
  {
    "url": "https://api-m.paypal.com",
    "description": "PayPal Live Environment"
  }
]
```

**Sanitized**:

```json
"servers": [
  {
    "url": "https://api-m.sandbox.paypal.com/v2/checkout",
    "description": "PayPal Sandbox Environment"
  },
  {
    "url": "https://api-m.paypal.com/v2/checkout",
    "description": "PayPal Live Environment"
  }
]
```

```diff
"servers": [
  {
-    "url": "https://api-m.sandbox.paypal.com",
+    "url": "https://api-m.sandbox.paypal.com/v2/checkout",
    "description": "PayPal Sandbox Environment"
  },
  {
-    "url": "https://api-m.paypal.com",
+    "url": "https://api-m.paypal.com/v2/checkout",
    "description": "PayPal Live Environment"
  }
]
```

**Reason**: Adding `/v2/checkout` to server URLs keeps versioning centralized.

## 2. Update `tokenUrl` to absolute URL

**Location**: `components.securitySchemes.Oauth2.flows.clientCredentials`

**Original**:

```json
"clientCredentials": {
  "tokenUrl": "/v1/oauth2/token",
  "scopes": {
    ...
  }
}
```

**Sanitized**:

```json
"clientCredentials": {
  "tokenUrl": "https://api-m.sandbox.paypal.com/v1/oauth2/token",
  "scopes": {
    ...
  }
}
```

```diff
"clientCredentials": {
-  "tokenUrl": "/v1/oauth2/token",
+  "tokenUrl": "https://api-m.sandbox.paypal.com/v1/oauth2/token",
  "scopes": {
    ...
  }
}
```

**Reason**: Prevents the relative path from being appended to the server URL, avoiding an invalid token endpoint.

## 3. Remove path prefix

**Location**: `paths`

**Original**:

```json
"paths": {
  "/v2/checkout/orders": { ... },
  "/v2/checkout/orders/{id}": { ... },
  "/v2/checkout/orders/{id}/confirm-payment-source": { ... },
  "/v2/checkout/orders/{id}/authorize": { ... },
  "/v2/checkout/orders/{id}/capture": { ... },
  "/v2/checkout/orders/{id}/track": { ... },
  "/v2/checkout/orders/{id}/trackers/{tracker_id}": { ... }
}
```

**Sanitized**:

```json
"paths": {
  "/orders": { ... },
  "/orders/{id}": { ... },
  "/orders/{id}/confirm-payment-source": { ... },
  "/orders/{id}/authorize": { ... },
  "/orders/{id}/capture": { ... },
  "/orders/{id}/track": { ... },
  "/orders/{id}/trackers/{tracker_id}": { ... }
}
```

```diff
"paths": {
-  "/v2/checkout/orders": { ... },
+  "/orders": { ... },
-  "/v2/checkout/orders/{id}": { ... },
+  "/orders/{id}": { ... },
-  "/v2/checkout/orders/{id}/confirm-payment-source": { ... },
+  "/orders/{id}/confirm-payment-source": { ... },
-  "/v2/checkout/orders/{id}/authorize": { ... },
+  "/orders/{id}/authorize": { ... },
-  "/v2/checkout/orders/{id}/capture": { ... },
+  "/orders/{id}/capture": { ... },
-  "/v2/checkout/orders/{id}/track": { ... },
+  "/orders/{id}/track": { ... },
-  "/v2/checkout/orders/{id}/trackers/{tracker_id}": { ... }
+  "/orders/{id}/trackers/{tracker_id}": { ... }
}
```

**Reason**: Removing `/v2/checkout` from paths makes them shorter and consistent now that the version is already in the server URLs.

## 4. Change default prefer header value

**Location**: `components.parameters.prefer`

**Original**:

```json
"prefer": {
  ...
  "schema": {
    ...
    "default": "return=minimal"
  }
}
```

**Sanitized**:

```json
"prefer": {
  ...
  "schema": {
    ...
    "default": "return=representation"
  }
}
```

```diff
"prefer": {
  ...
  "schema": {
    ...
-    "default": "return=minimal"
+    "default": "return=representation"
  }
}
```

**Reason**: Setting the default to return=representation means clients get the full response.

## 5. Rename `customer` to `wallet_customer`

**Location**: `components.schemas.PaypalWalletVaultResponseAllOf2`

**Original**:

```json
"PaypalWalletVaultResponseAllOf2" : {
  "properties" : {
    "customer" : {
      "$ref" : "#/components/schemas/paypal_wallet_customer"
    },
    ...
  }
}
```

**Sanitized**:

```json
"PaypalWalletVaultResponseAllOf2" : {
  "properties" : {
    "wallet_customer" : {
      "$ref" : "#/components/schemas/paypal_wallet_customer"
    },
    ...
  }
}
```

```diff
"PaypalWalletVaultResponseAllOf2" : {
  "properties" : {
-    "customer" : {
+    "wallet_customer" : {
      "$ref" : "#/components/schemas/paypal_wallet_customer"
    },
    ...
  }
}
```

**Reason**: Renaming `customer` to `wallet_customer` prevents redeclared symbol errors.

## OpenAPI CLI command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

> Note: The flattened OpenAPI specification must be used for Ballerina client generation to prevent type-inclusion [issue](https://github.com/ballerina-platform/ballerina-lang/issues/38535#issuecomment-2973521948) in the generated types.

```bash
bal openapi -i docs/spec/openapi.json --mode client -o ballerina
```
