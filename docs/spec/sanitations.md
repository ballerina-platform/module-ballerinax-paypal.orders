_Author_: @snelusha
_Created_: 18 June 2025
_Updated_: 18 June 2025
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Paypal Orders.
The OpenAPI specification is obtained from [PayPal’s official GitHub](https://github.com/paypal/paypal-rest-api-specifications/blob/main/openapi/checkout_orders_v2.json).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

## 1. Update OAuth2 token URL to relative URL.

**Location**: `components.securitySchemes.Oauth2.flows.clientCredentials.tokenUrl`

**Original**: `"tokenUrl": "/v1/oauth2/token"`

**Sanitized**: `"tokenUrl": "https://api-m.sandbox.paypal.com/v1/oauth2/token"`

```diff
- "tokenUrl": "/v1/oauth2/token"
+ "tokenUrl": "https://api-m.sandbox.paypal.com/v1/oauth2/token"
```

**Reason**: The relative path does not resolve correctly against the OAuth2 endpoint.

## 2. Replace `Schema'<Code>` keys with related status codes

**Original**:

```json
"Schema'400": {
    "properties": {
        "details": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/400Details"
            }
        }
    }
},
"Schema'401": {
    "properties": {
        "details": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/401Details"
            }
        }
    }
}
```

```json
"InlineResponse400": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Error400"
        },
        {
            "$ref": "#/components/schemas/Schema'400"
        }
    ]
},
"InlineResponse401": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Error401"
        },
        {
            "$ref": "#/components/schemas/Schema'401"
        }
    ]
}
```

**Sanitized**:

```json
"BadRequest": {
    "properties": {
        "details": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/400Details"
            }
        }
    }
},
"Unauthorized": {
    "properties": {
        "details": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/401Details"
            }
        }
    }
}
```

```json
"InlineResponse400": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Error400"
        },
        {
            "$ref": "#/components/schemas/BadRequest"
        }
    ]
},
"InlineResponse401": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Error401"
        },
        {
            "$ref": "#/components/schemas/Unauthorized"
        }
    ]
}
```

```diff
- "Schema'400": {
+ "BadRequest": {
    "properties": {
        "details": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/400Details"
            }
        }
    }
},
- "Schema'401": {
+ "Unauthorized": {
    "properties": {
        "details": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/401Details"
            }
        }
    }
}
```

```diff
"InlineResponse400": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Error400"
        },
        {
-           "$ref": "#/components/schemas/Schema'400"
+           "$ref": "#/components/schemas/BadRequest"
        }
    ]
},
"InlineResponse401": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Error401"
        },
        {
-            "$ref": "#/components/schemas/Schema'401"
+            "$ref": "#/components/schemas/Unauthorized"
        }
    ]
}
```

**Reason**: Apostrophes in schema names generate invalid JSON Schema; plain identifiers prevent generator errors.

**Reason**: JSON keys with apostrophes (e.g., `Schema'404`) are invalid and break schema parsing; using plain, descriptive identifiers (e.g., `NotFound`) ensures valid JSON Schema and prevents generator errors. See GitHub issue [#8011](https://github.com/ballerina-platform/ballerina-library/issues/8011) for details.


## 3. Remove `Money2` and `CurrencyCode2`; replace `Money2` references with `Money`

**Location**:

- `components.schemas.Money2` and `components.schemas.CurrencyCode2`
- `components.schemas.ApplePayDecryptedTokenData.properties.transaction_amount.allOf[0]`

**Original**:

```json
"Money2": {
    "title": "Money",
    "required": ["currency_code", "value"],
    "type": "object",
    "properties": {
        ...
    }
}
```

```json
"CurrencyCode2": {
    "maxLength": 3,
    "minLength": 3,
    ...
}
```

```json
"transaction_amount": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Money2"
        }
    ],
    "x-ballerina-name": "transactionAmount"
}
```

**Sanitized**:

```json
"transaction_amount": {
    "allOf": [
        {
            "$ref": "#/components/schemas/Money"
        }
    ],
    "x-ballerina-name": "transactionAmount"
}
```

```diff
- "Money2": {
-     "title": "Money",
-     "required": ["currency_code", "value"],
-     "type": "object",
-     "properties": {
-         ...
-     }
- }
```

```diff
- "CurrencyCode2": {
-     "maxLength": 3,
-     "minLength": 3,
-     ...
- }
```

```diff
"transaction_amount": {
    "allOf": [
        {
-           "$ref": "#/components/schemas/Money2"
+           "$ref": "#/components/schemas/Money"
        }
    ],
    "x-ballerina-name": "transactionAmount"
}
```

**Reason**:  `Money2` and `CurrencyCode2` duplicate the existing `Money` schema, so using one Money definition avoids redundancy

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

## 5. Override customer field to avoid redeclaration errors

**Location**: `components.schemas.PaypalWalletVaultResponse`

**Original**:

```json
"PaypalWalletVaultResponse": {
  ...
  "allOf": [
    {
      "$ref": "#/components/schemas/VaultResponse"
    },
    {
      "$ref": "#/components/schemas/PaypalWalletVaultResponseAllOf2"
    }
  ]
}
```

**Sanitized**:

```json
"PaypalWalletVaultResponse": {
  ...
  "allOf": [
    {
      "$ref": "#/components/schemas/VaultResponse"
    },
    {
      "$ref": "#/components/schemas/PaypalWalletVaultResponseAllOf2"
    },
    {
      "type": "object",
      "properties": {
        "customer": {
          "allOf": [
            {
              "$ref": "#/components/schemas/Customer"
            }
          ],
          "x-ballerina-name-ignore": "customer"
        }
      }
    }
  ]
}
```

```diff
"PaypalWalletVaultResponse": {
  ...
  "allOf": [
    {
      "$ref": "#/components/schemas/VaultResponse"
    },
    {
      "$ref": "#/components/schemas/PaypalWalletVaultResponseAllOf2"
-    }
+    },
+    {
+      "type": "object",
+      "properties": {
+        "customer": {
+          "allOf": [
+            {
+              "$ref": "#/components/schemas/Customer"
+            }
+          ],
+          "x-ballerina-name-ignore": "customer"
+        }
+      }
+    }
  ]
}
```

**Reason**: Prevent duplicate symbol conflicts by explicitly defining the `customer` property. Also addresses GitHub issue [#8042](https://github.com/ballerina-platform/ballerina-library/issues/8042)

## 6. Avoid json data annotations due to lang bug

**Original**:

```json
"x-ballerina-name": "countryCode"
```

**Sanitized**:

```json
"x-ballerina-name-ignore": "countryCode"
```

```diff
- "x-ballerina-name": "countryCode"
+ "x-ballerina-name-ignore": "countryCode"
```

**Reason**: Due to issue [#38535](https://github.com/ballerina-platform/ballerina-lang/issues/38535); the data binding fails for the fields which have json data name annotations. above chagne will avoid adding this annotations to the fields.

## OpenAPI CLI command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/openapi.json --mode client -o ballerina
```
