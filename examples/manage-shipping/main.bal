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

import ballerina/io;
import ballerina/uuid;
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

public function main(string orderId, string captureId) returns error? {
    string trackingNumber = uuid:createRandomUuid();

    paypal:Order response = check paypal->/orders/[orderId]/track.post({
        transaction_id: orderId,
        capture_id: captureId,
        tracking_number: trackingNumber,
        status: "NEW",
        carrier: "ARAMEX"
    });

    paypal:PurchaseUnit[] purchaseUnits = check response.purchase_units.ensureType();

    paypal:Tracker[] trackers = check purchaseUnits[0].shipping?.trackers.ensureType();

    paypal:Tracker tracker = trackers[0];

    string trackingId = check tracker.id.ensureType();

    io:println(string `Order(${orderId}) tracking information added (${trackingId})`);

    check paypal->/orders/[orderId]/trackers/[trackingId].patch([
        {
            op: "replace",
            path: "/status",
            value: "CANCELLED"
        }
    ]);

    io:println(string `Order(${orderId}) tracking information updated`);
}
