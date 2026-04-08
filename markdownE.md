# Simulated Database Specification
## Mobile Core Banking APIs

## 1. Purpose

This document defines the simulated database design and data models used to support the Mobile Core Banking API set.

The database is intended for:
- API simulation
- mock backend development
- integration testing
- QA test data seeding
- local development without dependency on real Core Banking

The simulated database supports the following APIs:

1. `MV/GetAccountsByRFC`
2. `MV/GetBasicInfoByCLABE`
3. `MV/GetBasicInfoByCardNumber`
4. `MV/GetBasicInfoByAccNumber`
5. `MV/GetClientInfoByAccNumber`
6. `MV/GetTransListByAccNumber`
7. `MV/InternalTransfer`
8. `MV/ExternalTransfer`
9. `MV/PersonalExternalTransfer`
10. `MV/VerifyPhoneNumber`

---

## 2. Design Principles

The simulated database is designed with the following principles:

- Keep the schema simple enough for mock implementation
- Preserve enough structure to simulate realistic business flows
- Support direct lookup by RFC, CLABE, card number, account number, and phone number
- Support transfer transaction history and transfer request persistence
- Support both retail and corporate customers
- Support one-to-many relationships between customer, accounts, cards, and transactions
- Support idempotency and request tracing for transfer APIs

---

## 3. Database Overview

## Main Entities

- `customers`
- `customer_addresses`
- `customer_identifications`
- `accounts`
- `cards`
- `users`
- `beneficiaries`
- `transactions`
- `transfer_requests`
- `transfer_destinations`
- `phone_verifications`

---

## 4. Entity Relationship Summary

```text
customers 1 --- n customer_addresses
customers 1 --- n customer_identifications
customers 1 --- n accounts
customers 1 --- n cards
customers 1 --- n users
customers 1 --- n beneficiaries
customers 1 --- n phone_verifications

accounts 1 --- n cards
accounts 1 --- n transactions

users 1 --- n transfer_requests
transfer_requests 1 --- n transfer_destinations
```

---
## 4.1 Keys and Relationships

### customers
- **PK:** `id`
- **UK:** `customer_number`, `client_code`
- **Referenced by:**
  - `customer_addresses.customer_id -> [customers.id](#customers)`
  - `customer_identifications.customer_id -> [customers.id](#customers)`
  - `accounts.customer_id -> [customers.id](#customers)`
  - `cards.customer_id -> [customers.id](#customers)`
  - `users.customer_id -> [customers.id](#customers)`
  - `beneficiaries.customer_id -> [customers.id](#customers)`
  - `phone_verifications.customer_id -> [customers.id](#customers)`

### customer_addresses
- **PK:** `id`
- **FK:**
  - `customer_id -> [customers.id](#customers)`

### customer_identifications
- **PK:** `id`
- **FK:**
  - `customer_id -> [customers.id](#customers)`

### accounts
- **PK:** `id`
- **UK:** `acc_number`, `clabe`
- **FK:**
  - `customer_id -> [customers.id](#customers)`
- **Referenced by:**
  - `cards.account_id -> [accounts.id](#accounts)`
  - `transactions.account_id -> [accounts.id](#accounts)`

### cards
- **PK:** `id`
- **UK:** `card_number`
- **FK:**
  - `customer_id -> [customers.id](#customers)`
  - `account_id -> [accounts.id](#accounts)`

### users
- **PK:** `id`
- **UK:** `user_id`, `username`
- **FK:**
  - `customer_id -> [customers.id](#customers)`
- **Referenced by:**
  - `transfer_requests.user_id -> [users.user_id](#users)`

### beneficiaries
- **PK:** `id`
- **UK:** `beneficiary_id`
- **FK:**
  - `customer_id -> [customers.id](#customers)`

### transactions
- **PK:** `id`
- **UK:** `trans_id`, `transaction_number`
- **FK:**
  - `account_id -> [accounts.id](#accounts)`

### transfer_requests
- **PK:** `id`
- **UK:** `req_id`
- **FK:**
  - `user_id -> [users.user_id](#users)`
- **Referenced by:**
  - `transfer_destinations.transfer_request_id -> [transfer_requests.id](#transfer_requests)`

### transfer_destinations
- **PK:** `id`
- **FK:**
  - `transfer_request_id -> [transfer_requests.id](#transfer_requests)`

### phone_verifications
- **PK:** `id`
- **UK:** `phone_number`
- **FK:**
  - `customer_id -> [customers.id](#customers)`

---


## 5. Table Specifications

## <a id="customers"></a>5.1 customers


Stores master customer profile for retail or corporate customer.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Internal primary key |
| customer_number | String | Yes | Customer identifier |
| client_code | String | Yes | Internal client code |
| client_type | String | Yes | `PERSONAL` or `MORAL` |
| category | String | No | Customer category |
| full_name | String | Yes | Full legal name |
| first_name | String | No | First name |
| middle_name | String | No | Middle name |
| first_last_name | String | No | First surname |
| middle_last_name | String | No | Second surname |
| rfc | String | Yes | RFC |
| curp | String | No | CURP |
| mobile_telephone | String | No | Mobile phone number |
| country_of_birth | String | No | Country of birth |
| economic_activity | String | No | Economic activity |
| economic_sector | String | No | Economic sector |
| gender | String | No | Gender |
| occupation | String | No | Occupation |
| date_of_birth_incorporation | Date | No | Date of birth or incorporation |
| country | String | No | Country |
| fiel_series | String | No | FIEL series |
| nationality | String | No | Nationality |
| file_reference | String | No | File or record reference |
| created_at | Timestamp | Yes | Created timestamp |
| updated_at | Timestamp | Yes | Updated timestamp |

### Constraints
- `id` is primary key
- `customer_number` must be unique
- `client_code` must be unique
- `rfc` should be indexed
- `mobile_telephone` should be indexed

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "customer_number": "CUST-554433",
  "client_code": "CLI-000123",
  "client_type": "MORAL",
  "category": "EMPRESARIAL",
  "full_name": "ACME SA DE CV",
  "first_name": "",
  "middle_name": "",
  "first_last_name": "",
  "middle_last_name": "",
  "rfc": "AAA010101AAA",
  "curp": "",
  "mobile_telephone": "5512345678",
  "country_of_birth": "MEXICO",
  "economic_activity": "SERVICES",
  "economic_sector": "FINANCE",
  "gender": "",
  "occupation": "",
  "date_of_birth_incorporation": "2005-01-01",
  "country": "MEXICO",
  "fiel_series": "",
  "nationality": "MEXICAN",
  "file_reference": "123456",
  "created_at": "2026-03-31T10:00:00Z",
  "updated_at": "2026-03-31T10:00:00Z"
}
```

---

<a id="customer_addresses"></a>
## 5.2 customer_addresses

Stores customer address information.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| customer_id | UUID | Yes | Reference to customer |
| street | String | No | Street |
| exterior_number | String | No | Exterior number |
| interior_number | String | No | Interior number |
| state_address | String | No | State |
| city_address | String | No | City |
| municipality_address | String | No | Municipality |
| neighborhood_address | String | No | Neighborhood |
| zip_code | String | No | Postal code |
| is_primary | Boolean | Yes | Primary address flag |

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc1001",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "street": "AV INSURGENTES SUR",
  "exterior_number": "100",
  "interior_number": "8",
  "state_address": "CDMX",
  "city_address": "CIUDAD DE MEXICO",
  "municipality_address": "BENITO JUAREZ",
  "neighborhood_address": "DEL VALLE",
  "zip_code": "03100",
  "is_primary": true
}
```

---

<a id="customer_identifications"></a>
## 5.3 customer_identifications

Stores identification information for customer.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| customer_id | UUID | Yes | Reference to customer |
| id_type | String | No | Identification type |
| id_number | String | No | Identification number |
| place_of_issue | String | No | Place of issue |
| date_of_issue | Date | No | Issue date |
| expiry_date | Date | No | Expiry date |

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc2001",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "id_type": "INE",
  "id_number": "ABC123456",
  "place_of_issue": "CDMX",
  "date_of_issue": "2020-01-01",
  "expiry_date": "2030-01-01"
}
```

---

<a id="accounts"></a>
## 5.4 accounts

Stores bank account information.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| customer_id | UUID | Yes | Owner customer |
| acc_number | String | Yes | Account number |
| clabe | String | No | CLABE |
| account_type | String | No | Account type |
| currency | String | Yes | Currency code |
| balance | Decimal(18,2) | Yes | Current balance |
| available_balance | Decimal(18,2) | Yes | Available balance |
| hold_balance | Decimal(18,2) | Yes | Hold amount |
| acc_name | String | No | Display account name |
| alias_account | String | No | Alias account |
| status | String | Yes | Account status |
| is_primary | Boolean | Yes | Primary account flag |
| bank_code | String | No | Bank code |
| bank_name | String | No | Bank name |
| created_at | Timestamp | Yes | Created timestamp |
| updated_at | Timestamp | Yes | Updated timestamp |

### Constraints
- `acc_number` must be unique
- `clabe` should be unique if present
- `customer_id` should be indexed

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc3001",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "acc_number": "1234567890",
  "clabe": "032180000118359719",
  "account_type": "40",
  "currency": "MXN",
  "balance": 250000.75,
  "available_balance": 245000.75,
  "hold_balance": 5000.00,
  "acc_name": "ACME SA DE CV",
  "alias_account": "Main Treasury",
  "status": "ACTIVE",
  "is_primary": true,
  "bank_code": "40030",
  "bank_name": "BANKAOOL",
  "created_at": "2026-03-31T10:00:00Z",
  "updated_at": "2026-03-31T10:00:00Z"
}
```

---

<a id="cards"></a>
## 5.5 cards

Stores debit or card mapping information linked to accounts.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| customer_id | UUID | Yes | Owner customer |
| account_id | UUID | Yes | Linked account |
| card_number | String | Yes | Full card number |
| masked_card_number | String | No | Masked card number |
| card_type | String | No | Debit or credit |
| status | String | Yes | Card status |
| expiry_month | Integer | No | Expiry month |
| expiry_year | Integer | No | Expiry year |
| created_at | Timestamp | Yes | Created timestamp |

### Constraints
- `card_number` must be unique

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc4001",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "account_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc3001",
  "card_number": "4111111111111111",
  "masked_card_number": "411111******1111",
  "card_type": "DEBIT",
  "status": "ACTIVE",
  "expiry_month": 12,
  "expiry_year": 2030,
  "created_at": "2026-03-31T10:00:00Z"
}
```

---

<a id="users"></a>
## 5.6 users

Stores online banking or mobile app user information.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| user_id | String | Yes | Public user id |
| customer_id | UUID | Yes | Linked customer |
| username | String | Yes | Username |
| email | String | No | Email |
| status | String | Yes | User status |
| has_online_banking | Boolean | Yes | Indicates online banking activation |
| mfa_enabled | Boolean | Yes | MFA enabled status |
| created_at | Timestamp | Yes | Created timestamp |
| updated_at | Timestamp | Yes | Updated timestamp |

### Constraints
- `user_id` must be unique
- `username` must be unique

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc5001",
  "user_id": "user-001",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "username": "treasury.user",
  "email": "treasury.user@acme.com",
  "status": "ACTIVE",
  "has_online_banking": true,
  "mfa_enabled": true,
  "created_at": "2026-03-31T10:00:00Z",
  "updated_at": "2026-03-31T10:00:00Z"
}
```

---

<a id="beneficiaries"></a>
## 5.7 beneficiaries

Stores saved internal or external transfer beneficiaries.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| beneficiary_id | String | Yes | Beneficiary identifier |
| customer_id | UUID | Yes | Owner customer |
| beneficiary_type | String | Yes | `INTERNAL` or `EXTERNAL` |
| alias_name | String | No | Saved alias name |
| dest_bank_code | String | No | Destination bank code |
| dest_bank_name | String | No | Destination bank name |
| dest_account_identifier | String | Yes | Destination account, CLABE, or card |
| dest_account_type | String | No | Destination account type |
| dest_beneficiary_name | String | No | Beneficiary name |
| dest_beneficiary_rfc | String | No | Beneficiary RFC |
| dest_phone_number | String | No | Beneficiary phone number |
| status | String | Yes | Beneficiary status |
| created_at | Timestamp | Yes | Created timestamp |

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc6001",
  "beneficiary_id": "BNF-0001",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "beneficiary_type": "EXTERNAL",
  "alias_name": "Juan BBVA",
  "dest_bank_code": "40012",
  "dest_bank_name": "BBVA",
  "dest_account_identifier": "646180157000000001",
  "dest_account_type": "40",
  "dest_beneficiary_name": "JUAN PEREZ",
  "dest_beneficiary_rfc": "PEJJ800101XXX",
  "dest_phone_number": "",
  "status": "ACTIVE",
  "created_at": "2026-03-31T10:00:00Z"
}
```

---

<a id="transactions"></a>
## 5.8 transactions

Stores transaction history for accounts.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| trans_id | String | Yes | Business transaction id |
| transaction_number | String | No | Core transaction number |
| req_id | String | No | Idempotency key |
| service | String | No | Service label |
| type | String | Yes | Transaction type |
| direction | String | Yes | `incoming` or `outgoing` |
| status | String | Yes | Transaction status |
| account_id | UUID | Yes | Reference to main account |
| origin_acc_number | String | No | Origin account number |
| origin_acc_name | String | No | Origin account name |
| origin_bank_code | String | No | Origin bank code |
| origin_clabe_number | String | No | Origin CLABE |
| origin_bank_name | String | No | Origin bank name |
| dest_acc_identifier | String | No | Destination account or identifier |
| dest_acc_name | String | No | Destination account name |
| dest_bank_code | String | No | Destination bank code |
| dest_bank_name | String | No | Destination bank name |
| dest_phone_number | String | No | Destination phone number |
| concept | String | No | Transfer concept |
| bank_reference | String | No | Bank reference |
| trace_number | String | No | SPEI trace number |
| amount | Decimal(18,2) | Yes | Amount |
| commission | Decimal(18,2) | Yes | Commission |
| vat | Decimal(18,2) | Yes | VAT |
| description | String | No | Description |
| keyword_search | Text | No | Searchable combined text |
| created_at | Timestamp | Yes | Creation date |
| updated_at | Timestamp | Yes | Updated date |

### Constraints
- `trans_id` must be unique
- `transaction_number` should be unique if present
- `account_id` should be indexed
- `trace_number` should be indexed

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc7001",
  "trans_id": "998877",
  "transaction_number": "EXT-000987655",
  "req_id": "7b4a4f43-c2c0-4e31-a75c-00a133f7ef21",
  "service": "Pago proveedor",
  "type": "SPEI",
  "direction": "outgoing",
  "status": "successful",
  "account_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc3001",
  "origin_acc_number": "1234567890",
  "origin_acc_name": "ACME SA DE CV",
  "origin_bank_code": "40030",
  "origin_clabe_number": "032180000118359719",
  "origin_bank_name": "BANKAOOL",
  "dest_acc_identifier": "646180157000000001",
  "dest_acc_name": "JUAN PEREZ",
  "dest_bank_code": "40012",
  "dest_bank_name": "BBVA",
  "dest_phone_number": "",
  "concept": "PAGO PROVEEDOR",
  "bank_reference": "REF-1001",
  "trace_number": "SPEI000123456",
  "amount": 1520.35,
  "commission": 0.00,
  "vat": 0.00,
  "description": "Pago proveedor",
  "keyword_search": "Pago proveedor JUAN PEREZ supplier BBVA",
  "created_at": "2026-03-31T10:30:00Z",
  "updated_at": "2026-03-31T10:30:00Z"
}
```

---

<a id="transfer_requests"></a>
## 5.9 transfer_requests

Stores transfer request headers for internal and external transfer APIs.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| req_id | String | No | Idempotency key |
| transaction_id | String | No | External transaction id |
| transfer_type | String | Yes | `INTERNAL`, `EXTERNAL`, `PERSONAL_EXTERNAL` |
| user_id | String | No | User identifier |
| customer_number | String | No | Customer identifier |
| client_code | String | No | Client code |
| username | String | No | Username |
| transfer_channel | String | No | Transfer channel |
| from_acc_number | String | Yes | Source account number |
| from_acc_rfc | String | No | Source account RFC |
| from_acc_name | String | No | Source account name |
| numeric_ref | String | No | Numeric reference |
| amount | Decimal(18,2) | Yes | Total amount |
| currency | String | No | Currency |
| charge_description | String | No | Charge description |
| concept | String | No | Transfer concept |
| payer_rfc | String | No | Payer RFC |
| payer_name | String | No | Payer name |
| geolocation_latitude | Decimal(12,8) | No | Latitude |
| geolocation_longitude | Decimal(12,8) | No | Longitude |
| signature_base64 | Text | No | Signature |
| source_system | String | No | Source system |
| transaction_code | String | No | Transaction code |
| payment_type | Integer | No | Payment type |
| session_code | Integer | No | Session code |
| commission_flag | String | No | Commission flag |
| status | String | Yes | Processing status |
| error_message | String | No | Error message |
| created_at | Timestamp | Yes | Created timestamp |
| updated_at | Timestamp | Yes | Updated timestamp |

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc8001",
  "req_id": "7b4a4f43-c2c0-4e31-a75c-00a133f7ef21",
  "transaction_id": "TXN-INT-20260331-001",
  "transfer_type": "INTERNAL",
  "user_id": "user-001",
  "customer_number": "CUST-554433",
  "client_code": "CLI-000123",
  "username": "treasury.user",
  "transfer_channel": "internal",
  "from_acc_number": "1234567890",
  "from_acc_rfc": "AAA010101AAA",
  "from_acc_name": "ACME SA DE CV",
  "numeric_ref": "100200",
  "amount": 1500.25,
  "currency": "MXN",
  "charge_description": "Internal transfer to savings",
  "concept": "Internal transfer to savings",
  "payer_rfc": "AAA010101AAA",
  "payer_name": "ACME SA DE CV",
  "geolocation_latitude": 19.4326,
  "geolocation_longitude": -99.1332,
  "signature_base64": null,
  "source_system": "BEM",
  "transaction_code": "SPEIM",
  "payment_type": 1,
  "session_code": 0,
  "commission_flag": "N",
  "status": "successful",
  "error_message": "",
  "created_at": "2026-03-31T10:20:00Z",
  "updated_at": "2026-03-31T10:20:00Z"
}
```

---

<a id="transfer_destinations"></a>
## 5.10 transfer_destinations

Stores destination-level records for external transfer flows.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| transfer_request_id | UUID | Yes | Reference to transfer request |
| destination_unique_id | Integer | No | Destination unique id |
| numeric_ref | String | No | Destination numeric reference |
| amount | Decimal(18,2) | Yes | Destination amount |
| payment_concept | String | No | Payment concept |
| dest_institution_code | String | No | Destination institution code |
| dest_account_number | String | Yes | Destination account number |
| dest_account_type | String | No | Destination account type |
| dest_beneficiary_name | String | No | Beneficiary name |
| dest_beneficiary_rfc | String | No | Beneficiary RFC |
| vat | Decimal(18,2) | No | VAT |
| billing_ref | String | No | Billing reference |
| receipt_url | String | No | Receipt URL |
| destination_transaction_number | String | No | Destination transaction number |
| tracking_key | String | No | SPEI tracking key |
| result_code | Integer | No | Result code |
| result_message | String | No | Result message |
| status | String | Yes | Destination status |
| created_at | Timestamp | Yes | Created timestamp |

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc9001",
  "transfer_request_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc8001",
  "destination_unique_id": 1,
  "numeric_ref": "100200",
  "amount": 2500.75,
  "payment_concept": "Invoice 1001",
  "dest_institution_code": "40012",
  "dest_account_number": "646180157000000001",
  "dest_account_type": "40",
  "dest_beneficiary_name": "JUAN PEREZ",
  "dest_beneficiary_rfc": "PEJJ800101XXX",
  "vat": 0.00,
  "billing_ref": "0",
  "receipt_url": "https://example.com/cep/SPEI000123456",
  "destination_transaction_number": "EXT-000987655",
  "tracking_key": "SPEI000123456",
  "result_code": 0,
  "result_message": "Transfer accepted",
  "status": "successful",
  "created_at": "2026-03-31T10:30:00Z"
}
```

---

<a id="phone_verifications"></a>
## 5.11 phone_verifications

Stores phone existence and online banking relationship for phone verification API.

| Field | Type | Required | Description |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| phone_number | String | Yes | Mobile phone number |
| customer_id | UUID | No | Reference to customer |
| is_exist | Boolean | Yes | Whether phone exists in core banking |
| has_online_banking | Boolean | Yes | Whether online banking is activated |
| verified_at | Timestamp | No | Last verification time |

### Constraints
- `phone_number` must be unique

### Sample Object
```json
{
  "id": "1f5f85c1-9db6-4ca8-824c-0c01d0dca001",
  "phone_number": "5512345678",
  "customer_id": "1f5f85c1-9db6-4ca8-824c-0c01d0dc0001",
  "is_exist": true,
  "has_online_banking": true,
  "verified_at": "2026-03-31T10:00:00Z"
}
```

---

## 6. Enum Definitions

## 6.1 customer_client_type
```text
PERSONAL
MORAL
```

## 6.2 account_status
```text
ACTIVE
BLOCKED
CLOSED
DORMANT
```

## 6.3 card_status
```text
ACTIVE
BLOCKED
EXPIRED
CANCELLED
```

## 6.4 user_status
```text
ACTIVE
LOCKED
DISABLED
```

## 6.5 beneficiary_type
```text
INTERNAL
EXTERNAL
```

## 6.6 transaction_direction
```text
incoming
outgoing
```

## 6.7 transaction_status
```text
pending
successful
failed
reversed
cancelled
```

## 6.8 transfer_type
```text
INTERNAL
EXTERNAL
PERSONAL_EXTERNAL
```

---

## 7. API to Table Mapping

| API Name | Main Tables Used |
|---|---|
| MV/GetAccountsByRFC | customers, accounts |
| MV/GetBasicInfoByCLABE | accounts, customers |
| MV/GetBasicInfoByCardNumber | cards, accounts, customers |
| MV/GetBasicInfoByAccNumber | accounts, customers |
| MV/GetClientInfoByAccNumber | accounts, customers, customer_addresses, customer_identifications |
| MV/GetTransListByAccNumber | accounts, transactions |
| MV/InternalTransfer | transfer_requests, transactions |
| MV/ExternalTransfer | transfer_requests, transfer_destinations, transactions |
| MV/PersonalExternalTransfer | transfer_requests, transfer_destinations, transactions |
| MV/VerifyPhoneNumber | phone_verifications, customers, users |

---

## 8. Recommended Seed Data

The simulation environment should include at least:

### Customers
- 1 corporate customer with primary account and online banking enabled
- 1 personal customer with multiple accounts
- 1 personal customer without online banking

### Accounts
- 5 total accounts
- at least 1 primary account
- at least 1 blocked account
- at least 1 secondary account

### Cards
- 3 cards
- at least 1 active card
- at least 1 expired or blocked card

### Beneficiaries
- 2 internal beneficiaries
- 2 external beneficiaries

### Transactions
- 30 to 50 transactions
- mixed incoming and outgoing
- mixed successful, pending, failed
- spread across multiple dates for filter testing

### Transfer Requests
- 5 internal transfer requests
- 5 external or personal external transfer requests

### Phone Verifications
- 3 phone verification records
- 1 existing with online banking
- 1 existing without online banking
- 1 non-existing number

---

## 9. Repository-Level Query Rules for Simulation

## 9.1 GetAccountsByRFC
- Find customer by `rfc`
- Return all accounts belonging to the customer
- Aggregate total balance from accounts
- Return primary account alias when available

## 9.2 GetBasicInfoByCLABE
- Find account by `clabe`
- Join customer by `customer_id`
- Return `full_name` and `rfc`

## 9.3 GetBasicInfoByCardNumber
- Find card by `card_number`
- Join account and customer
- Return `full_name` and `rfc`

## 9.4 GetBasicInfoByAccNumber
- Find account by `acc_number`
- Join customer
- Return `full_name` and `rfc`

## 9.5 GetClientInfoByAccNumber
- Find account by `acc_number`
- Join customer
- Join primary address
- Join latest valid identification
- Return flattened customer detail payload

## 9.6 GetTransListByAccNumber
- Find account by `account_number`
- Load transactions by `account_id`
- Support filters:
  - `status`
  - `direction`
  - `start_time`
  - `end_time`
  - `keyword`
- Support cursor pagination by `last_id`
- Sort by `created_at desc`

## 9.7 InternalTransfer
- Validate source and destination accounts
- Validate source balance
- Create transfer request
- Create transaction record
- Update balances
- Return generated transaction number

## 9.8 ExternalTransfer
- Validate source account
- Validate signature and payload
- Create transfer request
- Create one or many destination rows
- Create one transaction record per processed destination or one aggregate header + detail records
- Return origin transaction number and per-destination results

## 9.9 PersonalExternalTransfer
- Validate source account
- Resolve destination from flattened payload
- Create transfer request
- Create one transfer destination row
- Create one transaction record
- Return `trans_number`, `trace_number`, and `receipt_url`

## 9.10 VerifyPhoneNumber
- Lookup by `phone_number`
- Return `is_exist`
- Return `has_online_banking`

---

## 10. Known Notes for Spec Clarification

## 10.1 Endpoint inconsistency
The API `MV/GetClientInfoByAccNumber` currently uses endpoint:

```text
{{host}}/api/FX/GetClientInfoByAccNumber
```

This should be re-confirmed because naming convention suggests it may belong under `MV`.

## 10.2 VerifyPhoneNumber example inconsistency
The request field is defined as:

```text
phone_number
```

But the example request shows:

```json
{
  "acc_number": "1234567890"
}
```

For simulation purposes, the database model should follow `phone_number` as the correct input field.

---

## 11. Suggested Future Extensions

If needed later, the simulated database can be extended with:

- `audit_logs`
- `mfa_devices`
- `receipts`
- `transfer_signatures`
- `account_holds`
- `exchange_rates`
- `banks_catalog`
- `transaction_status_history`

---

## 12. Final Recommendation

For mock backend implementation:
- use relational structure
- use UUID as internal PK
- keep business identifiers like `customer_number`, `acc_number`, `clabe`, `card_number`, and `user_id` as unique indexed fields
- keep transfer request and transaction history separate
- keep API response payload mapping close to source tables to simplify mock service logic
