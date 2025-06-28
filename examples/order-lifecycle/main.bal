import ballerina/io;
import ballerinax/paypal.orders as paypal;

configurable string clientId = ?;
configurable string clientSecret = ?;

configurable string serviceUrl = ?;
configurable string tokenUrl = ?;

final paypal:Client paypal = check new ({
    auth: {
        clientId,
        clientSecret,
        tokenUrl
    }
}, serviceUrl);

public function main() returns error? {
    paypal:Order createOrderResponse = check paypal->/orders.post({
        intent: "CAPTURE",
        purchase_units: [{
                amount: {
                    currency_code: "USD",
                    value: "100.00"
                }
            }]
    });

    string orderId = check createOrderResponse.id.ensureType();
    io:println(string `Order(${orderId}) created`);

    check paypal->/orders/[orderId].patch([
        {
            op: "add",
            path: "/purchase_units/@reference_id=='default'/amount",
            value: {
                currency_code: "USD",
                value: "200.00",
                breakdown: {
                    item_total: {
                        currency_code: "USD",
                        value: "150.00"
                    },
                    shipping: {
                        currency_code: "USD",
                        value: "50.00"
                    }
                }
            }
        }
    ]);

    io:println(string `Order(${orderId}) amount updated with breakdown`);

    paypal:Order _ = check paypal->/orders/[orderId]/confirm\-payment\-source.post({
            payment_source: {
                card: {
                    number: "4032037064388131",
                    expiry: "2035-12"
                }
            }
        });

    io:println(string `Order(${orderId}) payment source confirmed`);

    paypal:Order orderCaptureResponse = check paypal->/orders/[orderId]/capture.post({
        payment_source: {
            card: {
                name: "John Doe",
                number: "4032037064388131",
                expiry: "2035-12"
            }
        }
    });

    paypal:PurchaseUnit[] purchaseUnits = check orderCaptureResponse.purchase_units.ensureType();
    
    paypal:Capture[] captures =  check purchaseUnits[0]?.payments?.captures.ensureType();

    paypal:Capture capture = captures[0];

    string captureId = check capture.id.ensureType();

    io:println(string `Order(${orderId}) captured (${captureId})`);
}
