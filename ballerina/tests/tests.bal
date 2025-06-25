// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/os;
import ballerina/lang.runtime;
import ballerina/log;

import ballerina/uuid;
import ballerina/test;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

configurable string clientId = os:getEnv("PAYPAL_CLIENT_ID");
configurable string clientSecret = os:getEnv("PAYPAL_CLIENT_SECRET");

final string serviceUrl = isLiveServer ? "https://api-m.sandbox.paypal.com/v2/checkout" : "http://localhost:9090";
final string tokenUrl = isLiveServer ? "https://api-m.sandbox.paypal.com/v1/oauth2/token" : "http://localhost:9444/oauth2/token";

Client paypal = test:mock(Client);

string captureOrderId = "";
string captureOrderPaymentCaptureId = "";
string captureOrderTrackingId = "";

string authorizeOrderId = "";

PurchaseUnitRequest[] purchaseUnits = [
    {
        amount: {
            value: "200.00",
            currency_code: "USD",
            breakdown: {
                item_total: {
                    currency_code: "USD",
                    value: "180.00"
                },
                shipping: {
                    value: "20.00",
                    currency_code: "USD"
                }
            }
        }
    }
];

@test:BeforeSuite
function initClient() returns error? {
    if isLiveServer {
        paypal = check new ({auth: {clientId, clientSecret, tokenUrl}}, serviceUrl);
    } else {
        check stsListener.attach(sts, "/oauth2");
        check stsListener.'start();

        runtime:registerListener(stsListener);
        log:printInfo("STS started on port: " + HTTP_SERVER_PORT.toString() + " (HTTP)");

        paypal = check new ({auth: {clientId, clientSecret, tokenUrl}}, serviceUrl);
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function createCaptureOrder() returns error? {
    Order response = check paypal->/orders.post({
        intent: "CAPTURE",
        purchase_units: purchaseUnits
    });

    test:assertNotEquals(response.id, ());

    captureOrderId = check response.id.ensureType();

    test:assertEquals(response.intent, "CAPTURE");
    test:assertEquals(response.status, "CREATED");
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [createCaptureOrder]
}
function getCaptureOrder() returns error? {
    Order response = check paypal->/orders/[captureOrderId].get();

    test:assertEquals(response.id, captureOrderId);
    test:assertEquals(response.intent, "CAPTURE");
    test:assertEquals(response.status, "CREATED");

    test:assertNotEquals(response.create_time, ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [getCaptureOrder]
}
function updateCaptureOrder() returns error? {
    string invoiceId = uuid:createRandomUuid().toString();

    check paypal->/orders/[captureOrderId].patch([
        {
            op: "add",
            path: "/purchase_units/@reference_id=='default'/invoice_id",
            value: invoiceId
        }
    ]);
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [updateCaptureOrder]
}
function confirmCaptureOrderPaymentSource() returns error? {
    Order response = check paypal->/orders/[captureOrderId]/confirm\-payment\-source.post({
        payment_source: {
            card: {
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    test:assertEquals(response.id, captureOrderId);
    test:assertEquals(response.status, "APPROVED");

    PaymentSourceResponse ps = check response.payment_source.ensureType();
    CardResponse cr = check ps.card.ensureType();

    test:assertEquals(cr.last_digits, "8131");
    test:assertEquals(cr.expiry, "2035-12");
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [confirmCaptureOrderPaymentSource]
}
function captureOrder() returns error? {
    Order response = check paypal->/orders/[captureOrderId]/capture.post({
        payment_source: {
            card: {
                name: "John Doe",
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    test:assertEquals(response.id, captureOrderId);
    test:assertEquals(response.status, "COMPLETED");

    test:assertNotEquals(response.purchase_units, ());

    PurchaseUnit[] purchaseUnits = check response.purchase_units.ensureType();
    test:assertEquals(purchaseUnits.length(), 1);

    PurchaseUnit pu = purchaseUnits[0];
    test:assertEquals(pu.reference_id, "default");

    PaymentCollection pc = check pu.payments.ensureType();
    Capture[] captures = check pc.captures.ensureType();
    test:assertEquals(captures.length(), 1);

    Capture cap = captures[0];
    test:assertEquals(cap.status, "COMPLETED");
    test:assertNotEquals(cap.id, ());

    captureOrderPaymentCaptureId = check cap.id.ensureType();
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [captureOrder]
}
function addTrackingInfo() returns error? {
    string trackingNumber = uuid:createRandomUuid().toString();

    Order response = check paypal->/orders/[captureOrderId]/track.post({
        transaction_id: captureOrderId,
        capture_id: captureOrderPaymentCaptureId,
        tracking_number: trackingNumber,
        status: "IN_TRANSIT",
        carrier: "DPD_RU"
    });

    PurchaseUnit[] purchaseUnits = check response.purchase_units.ensureType();
    test:assertEquals(purchaseUnits.length(), 1);

    PurchaseUnit pu = purchaseUnits[0];
    test:assertEquals(pu.reference_id, "default");

    ShippingWithTrackingDetails trackingDetails = check pu.shipping.ensureType();

    test:assertNotEquals(trackingDetails, ());

    Tracker[] trackers = check trackingDetails.trackers.ensureType();
    test:assertEquals(trackers.length(), 1);

    Tracker tr = trackers[0];
    captureOrderTrackingId = check tr.id.ensureType();
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [addTrackingInfo]
}
function updateTrackingInfo() returns error? {
    check paypal->/orders/[captureOrderId]/trackers/[captureOrderTrackingId].patch([
        {
            op: "replace",
            path: "/status",
            value: "CANCELLED"
        }
    ]);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function createAuthorizeOrder() returns error? {
    Order response = check paypal->/orders.post({
        intent: "AUTHORIZE",
        purchase_units: purchaseUnits
    });

    test:assertNotEquals(response.id, ());

    authorizeOrderId = check response.id.ensureType();

    test:assertEquals(response.intent, "AUTHORIZE");
    test:assertEquals(response.status, "CREATED");
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [createAuthorizeOrder]
}
function getAuthorizeOrder() returns error? {
    Order response = check paypal->/orders/[authorizeOrderId].get();

    test:assertEquals(response.id, authorizeOrderId);
    test:assertEquals(response.intent, "AUTHORIZE");
    test:assertEquals(response.status, "CREATED");

    test:assertNotEquals(response.create_time, ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [getAuthorizeOrder]
}
function confirmAuthorizeOrderPaymentSource() returns error? {
    Order response = check paypal->/orders/[authorizeOrderId]/confirm\-payment\-source.post({
        payment_source: {
            card: {
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    test:assertEquals(response.id, authorizeOrderId);
    test:assertEquals(response.status, "APPROVED");

    PaymentSourceResponse ps = check response.payment_source.ensureType();
    CardResponse cr = check ps.card.ensureType();

    test:assertEquals(cr.last_digits, "8131");
    test:assertEquals(cr.expiry, "2035-12");
}

@test:Config {
    groups: ["live_tests", "mock_tests"],
    dependsOn: [confirmAuthorizeOrderPaymentSource]
}
function authorizeOrder() returns error? {
    OrderAuthorizeResponse response = check paypal->/orders/[authorizeOrderId]/authorize.post({});

    test:assertEquals(response.id, authorizeOrderId);
    test:assertEquals(response.status, "COMPLETED");

    test:assertNotEquals(response.purchase_units, ());

    PurchaseUnit[] purchaseUnits = check response.purchase_units.ensureType();
    test:assertEquals(purchaseUnits.length(), 1);

    PurchaseUnit pu = purchaseUnits[0];
    test:assertEquals(pu.reference_id, "default");

    PaymentCollection pc = check pu.payments.ensureType();
    AuthorizationWithAdditionalData[] authorizations = check pc.authorizations.ensureType();
    test:assertEquals(authorizations.length(), 1);

    AuthorizationWithAdditionalData auth = authorizations[0];
    test:assertEquals(auth.status, "CREATED");
    test:assertNotEquals(auth.id, ());

    captureOrderPaymentCaptureId = check auth.id.ensureType();
}
