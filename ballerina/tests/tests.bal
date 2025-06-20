import ballerina/os;
import ballerina/test;
import ballerina/uuid;

import paypal.orders.mock as _;

configurable boolean isLiveServer = true;

configurable string clientId = os:getEnv("PAYPAL_CLIENT_ID");
configurable string clientSecret = os:getEnv("PAYPAL_CLIENT_SECRET");

final string serviceUrl = isLiveServer ? "https://api-m.sandbox.paypal.com/v2/checkout" : "http://localhost:9090";
final string tokenUrl = isLiveServer ? "https://api-m.sandbox.paypal.com/v1/oauth2/token" : "http://localhost:9444/oauth2/token";

Client paypal = test:mock(Client);

string captureOrderId = "";
string captureOrderPaymentCaptureId = "";
string captureOrderTrackingId = "";

string authorizeOrderId = "";

purchase_unit_request[] purchaseUnits = [
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
    if (isLiveServer) {
        paypal = check new ({auth: {clientId, clientSecret, tokenUrl}}, serviceUrl);
    } else {
        paypal = check new ({auth: {clientId, clientSecret, tokenUrl}}, serviceUrl);
    }
}

@test:Config
function createCaptureOrder() returns error? {
    'order response = check paypal->/orders.post({
        intent: "CAPTURE",
        purchase_units: purchaseUnits
    });

    test:assertNotEquals(response, ());
    test:assertNotEquals(response.id, ());

    captureOrderId = <string>response.id;

    test:assertEquals(response.intent, "CAPTURE");
    test:assertEquals(response.status, "CREATED");
}

@test:Config {
    dependsOn: [createCaptureOrder]
}
function getCaptureOrder() returns error? {
    'order response = check paypal->/orders/[captureOrderId].get();

    test:assertNotEquals(response, ());

    test:assertEquals(response.id, captureOrderId);
    test:assertEquals(response.intent, "CAPTURE");
    test:assertEquals(response.status, "CREATED");

    test:assertNotEquals(response.create_time, ());
}

@test:Config {
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
    dependsOn: [updateCaptureOrder]
}
function confirmCaptureOrderPaymentSource() returns error? {
    'order response = check paypal->/orders/[captureOrderId]/confirm\-payment\-source.post({
        payment_source: {
            card: {
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    test:assertNotEquals(response, ());

    test:assertEquals(response.id, captureOrderId);
    test:assertEquals(response.status, "APPROVED");

    payment_source_response ps = <payment_source_response>response.payment_source;
    card_response cr = <card_response>ps.card;

    test:assertEquals(cr.last_digits, "8131");
    test:assertEquals(cr.expiry, "2035-12");
}

@test:Config {
    dependsOn: [confirmCaptureOrderPaymentSource]
}
function captureOrder() returns error? {
    'order response = check paypal->/orders/[captureOrderId]/capture.post({
        payment_source: {
            card: {
                name: "John Doe",
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    test:assertNotEquals(response, ());

    test:assertEquals(response.id, captureOrderId);
    test:assertEquals(response.status, "COMPLETED");

    test:assertNotEquals(response.purchase_units, ());

    purchase_unit[] purchaseUnits = <purchase_unit[]>response.purchase_units;
    test:assertEquals(purchaseUnits.length(), 1);

    purchase_unit pu = purchaseUnits[0];
    test:assertEquals(pu.reference_id, "default");

    payment_collection pc = <payment_collection>pu.payments;
    capture[] captures = <capture[]>pc.captures;
    test:assertEquals(captures.length(), 1);

    capture cap = captures[0];
    test:assertEquals(cap.status, "COMPLETED");
    test:assertNotEquals(cap.id, ());

    captureOrderPaymentCaptureId = <string>cap.id;
}

@test:Config {
    dependsOn: [captureOrder]
}
function addTrackingInfo() returns error? {
    string trackingNumber = uuid:createRandomUuid().toString();

    'order response = check paypal->/orders/[captureOrderId]/track.post({
        transaction_id: captureOrderId,
        capture_id: captureOrderPaymentCaptureId,
        tracking_number: trackingNumber,
        status: "IN_TRANSIT",
        carrier: "DPD_RU"
    });

    test:assertNotEquals(response, ());

    purchase_unit[] purchaseUnits = <purchase_unit[]>response.purchase_units;
    test:assertEquals(purchaseUnits.length(), 1);

    purchase_unit pu = purchaseUnits[0];
    test:assertEquals(pu.reference_id, "default");

    shipping_with_tracking_details trackingDetails = <shipping_with_tracking_details>pu.shipping;

    test:assertNotEquals(trackingDetails, ());

    tracker[] trackers = <tracker[]>trackingDetails.trackers;
    test:assertEquals(trackers.length(), 1);

    tracker tr = trackers[0];
    captureOrderTrackingId = <string>tr.id;
}

@test:Config {
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

@test:Config
function createAuthorizeOrder() returns error? {
    'order response = check paypal->/orders.post({
        intent: "AUTHORIZE",
        purchase_units: purchaseUnits
    });

    test:assertNotEquals(response, ());
    test:assertNotEquals(response.id, ());

    authorizeOrderId = <string>response.id;

    test:assertEquals(response.intent, "AUTHORIZE");
    test:assertEquals(response.status, "CREATED");
}

@test:Config {
    dependsOn: [createAuthorizeOrder]
}
function getAuthorizeOrder() returns error? {
    'order response = check paypal->/orders/[authorizeOrderId].get();

    test:assertNotEquals(response, ());

    test:assertEquals(response.id, authorizeOrderId);
    test:assertEquals(response.intent, "AUTHORIZE");
    test:assertEquals(response.status, "CREATED");

    test:assertNotEquals(response.create_time, ());
}

@test:Config {
    dependsOn: [getAuthorizeOrder]
}
function confirmAuthorizeOrderPaymentSource() returns error? {
    'order response = check paypal->/orders/[authorizeOrderId]/confirm\-payment\-source.post({
        payment_source: {
            card: {
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    test:assertNotEquals(response, ());

    test:assertEquals(response.id, authorizeOrderId);
    test:assertEquals(response.status, "APPROVED");

    payment_source_response ps = <payment_source_response>response.payment_source;
    card_response cr = <card_response>ps.card;

    test:assertEquals(cr.last_digits, "8131");
    test:assertEquals(cr.expiry, "2035-12");
}

@test:Config {
    dependsOn: [confirmAuthorizeOrderPaymentSource]
}
function authorizeOrder() returns error? {
   order_authorize_response response = check paypal->/orders/[authorizeOrderId]/authorize.post({});

    test:assertNotEquals(response, ());

    test:assertEquals(response.id, authorizeOrderId);
    test:assertEquals(response.status, "COMPLETED");

    test:assertNotEquals(response.purchase_units, ());

    purchase_unit[] purchaseUnits = <purchase_unit[]>response.purchase_units;
    test:assertEquals(purchaseUnits.length(), 1);

    purchase_unit pu = purchaseUnits[0];
    test:assertEquals(pu.reference_id, "default");

    payment_collection pc = <payment_collection>pu.payments;
    authorization_with_additional_data[] authorizations = <authorization_with_additional_data[]>pc.authorizations;
    test:assertEquals(authorizations.length(), 1);

    authorization_with_additional_data auth = authorizations[0];
    test:assertEquals(auth.status, "CREATED");
    test:assertNotEquals(auth.id, ());

    captureOrderPaymentCaptureId = <string>auth.id;
}
