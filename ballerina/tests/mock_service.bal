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

import ballerina/http;

final purchase_unit[] & readonly pUnits = [
    {
        reference_id: "default",
        amount: {
            currency_code: "USD",
            value: "200.00",
            breakdown: {
                item_total: {
                    currency_code: "USD",
                    value: "180.00"
                },
                shipping: {
                    currency_code: "USD",
                    value: "20.00"
                }
            }
        },
        payee: {
            email_address: "sb-wrafi36853704@business.example.com",
            merchant_id: "M6V5C6A45Z32W"
        }
    }
];

final 'order & readonly sampleCaptureOrder = {
    id: "6JE657202M751084B",
    intent: "CAPTURE",
    status: "CREATED",
    purchase_units: pUnits,
    create_time: "2025-06-17T08:53:19Z"
};

final 'order & readonly sampleAuthorizeOrder = {
    id: "6JE657202M751084C",
    intent: "AUTHORIZE",
    status: "CREATED",
    purchase_units: pUnits,
    create_time: "2025-06-17T08:53:19Z"
};

service on new http:Listener(9090) {
    resource isolated function post orders(@http:Payload order_request payload) returns 'order|http:NotFound {
        if payload.intent == "CAPTURE" {
            return sampleCaptureOrder;
        } else if payload.intent == "AUTHORIZE" {
            return sampleAuthorizeOrder;
        }
        return http:NOT_FOUND;
    }

    resource isolated function get orders/[string id]() returns 'order|http:NotFound {
        if id == sampleCaptureOrder.id {
            return sampleCaptureOrder;
        } else if id == sampleAuthorizeOrder.id {
            return sampleAuthorizeOrder;
        }
        return http:NOT_FOUND;
    }

    resource isolated function patch orders/[string id](patch_request payload) returns error? {
        return ();
    }

    resource isolated function post orders/[string id]/confirm\-payment\-source(confirm_order_request payload) returns 'order|http:NotFound {
        payment_source_response ps = {
            card: {
                name: "John Doe",
                last_digits: "8131",
                expiry: "2035-12",
                brand: "VISA",
                available_networks: ["VISA"],
                'type: "CREDIT",
                bin_details: {
                    bin: "403203",
                    issuing_bank: "Baxter Credit Union",
                    bin_country_code: "US"
                }
            }
        };

        if id == sampleCaptureOrder.id {
            return {
                id: sampleCaptureOrder.id,
                intent: sampleCaptureOrder.intent,
                status: "APPROVED",
                purchase_units: sampleCaptureOrder.purchase_units,
                payment_source: ps,
                create_time: sampleCaptureOrder.create_time
            };
        }
        else if id == sampleAuthorizeOrder.id {
            return {
                id: sampleAuthorizeOrder.id,
                intent: sampleAuthorizeOrder.intent,
                status: "APPROVED",
                purchase_units: sampleAuthorizeOrder.purchase_units,
                payment_source: ps,
                create_time: sampleAuthorizeOrder.create_time
            };
        }
        else {
            return http:NOT_FOUND;
        }
    }

    resource isolated function post orders/[string id]/capture(order_capture_request payload) returns 'order|http:NotFound|error {
        if id == sampleCaptureOrder.id {
            'order capturedOrder = check sampleCaptureOrder.cloneWithType('order);
            purchase_unit[]? ps = capturedOrder.purchase_units;
            if ps is purchase_unit[] {
                ps[0].payments = {
                    captures: [
                        {
                            id: "6JE657202M751084D",
                            status: "COMPLETED",
                            amount: {
                                currency_code: "USD",
                                value: "200.00"
                            },
                            create_time: "2025-06-17T08:53:19Z"
                        }
                    ]
                };
            }

            return {
                id: capturedOrder.id,
                intent: capturedOrder.intent,
                status: "COMPLETED",
                purchase_units: capturedOrder.purchase_units,
                create_time: capturedOrder.create_time
            };
        } else {
            return http:NOT_FOUND;
        }
    }

    resource isolated function post orders/[string id]/authorize(order_authorize_request payload) returns order_authorize_response|http:NotFound|error {
        if id == sampleAuthorizeOrder.id {
            'order authorizedOrder = check sampleAuthorizeOrder.cloneWithType('order);
            purchase_unit[]? ps = authorizedOrder.purchase_units;
            if ps is purchase_unit[] {
                ps[0].payments = {
                    authorizations: [
                        {
                            id: "6JE657202M751084E",
                            status: "CREATED",
                            amount: {
                                currency_code: "USD",
                                value: "200.00"
                            },
                            create_time: "2025-06-17T08:53:19Z"
                        }
                    ]
                };
            }

            return {
                id: authorizedOrder.id,
                intent: authorizedOrder.intent,
                status: "COMPLETED",
                purchase_units: authorizedOrder.purchase_units,
                create_time: authorizedOrder.create_time
            };
        } else {
            return http:NOT_FOUND;
        }
    }

    resource isolated function post orders/[string id]/track(order_tracker_request payload) returns 'order|http:NotFound|error {
        if id == sampleCaptureOrder.id {
            'order trackedOrder = check sampleCaptureOrder.cloneWithType('order);
            purchase_unit[]? ps = trackedOrder.purchase_units;
            if ps is purchase_unit[] {
                ps[0].shipping = {
                    trackers: [
                        {
                            id: "TRACKER123456",
                            "tracking_number": payload.tracking_number,
                            "status": payload.status
                        }
                    ]
                };
            }

            return {
                id: trackedOrder.id,
                intent: trackedOrder.intent,
                status: trackedOrder.status,
                purchase_units: trackedOrder.purchase_units,
                create_time: trackedOrder.create_time
            };
        } else {
            return http:NOT_FOUND;
        }
    }

    resource isolated function patch orders/[string id]/trackers/[string tracker_id](patch_request payload) returns error? {
        return ();
    }
};
