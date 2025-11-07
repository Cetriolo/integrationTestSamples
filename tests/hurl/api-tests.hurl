# Health Check Tests
GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.version" exists
jsonpath "$.timestamp" exists
duration < 500

GET {{base_url}}/ready
HTTP 200
[Asserts]
jsonpath "$.ready" == true
jsonpath "$.checks.database" == true
jsonpath "$.checks.cache" == true

GET {{base_url}}/version
HTTP 200
[Asserts]
jsonpath "$.version" exists
jsonpath "$.build_date" exists
jsonpath "$.go_version" exists

# User CRUD Tests
GET {{base_url}}/api/users
HTTP 200
[Asserts]
jsonpath "$" isCollection
duration < 1000

POST {{base_url}}/api/users
Content-Type: application/json
{
  "name": "Hurl Test User",
  "email": "hurl@example.com"
}
HTTP 201
[Captures]
user_id: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists
jsonpath "$.name" == "Hurl Test User"
jsonpath "$.email" == "hurl@example.com"
jsonpath "$.created_at" exists

GET {{base_url}}/api/users/{{user_id}}
HTTP 200
[Asserts]
jsonpath "$.id" == {{user_id}}
jsonpath "$.name" == "Hurl Test User"
jsonpath "$.email" == "hurl@example.com"

PUT {{base_url}}/api/users/{{user_id}}
Content-Type: application/json
{
  "name": "Updated Hurl User"
}
HTTP 200
[Asserts]
jsonpath "$.name" == "Updated Hurl User"
jsonpath "$.id" == {{user_id}}

DELETE {{base_url}}/api/users/{{user_id}}
HTTP 204

GET {{base_url}}/api/users/{{user_id}}
HTTP 404

# Product Tests
GET {{base_url}}/api/products
HTTP 200
[Asserts]
jsonpath "$" isCollection
jsonpath "$[0].id" exists
jsonpath "$[0].name" exists
jsonpath "$[0].price" exists
jsonpath "$[0].stock" exists

POST {{base_url}}/api/products
Content-Type: application/json
{
  "name": "Hurl Test Product",
  "price": 99.99,
  "stock": 50
}
HTTP 201
[Captures]
product_id: jsonpath "$.id"
[Asserts]
jsonpath "$.name" == "Hurl Test Product"
jsonpath "$.price" == 99.99
jsonpath "$.stock" == 50

GET {{base_url}}/api/products/{{product_id}}
HTTP 200
[Asserts]
jsonpath "$.id" == {{product_id}}

PUT {{base_url}}/api/products/{{product_id}}
Content-Type: application/json
{
  "name": "Updated Product",
  "price": 149.99
}
HTTP 200
[Asserts]
jsonpath "$.name" == "Updated Product"
jsonpath "$.price" == 149.99

# Error Handling Tests
GET {{base_url}}/api/users/99999
HTTP 404
[Asserts]
jsonpath "$.error" exists
jsonpath "$.code" == 404
jsonpath "$.message" exists

GET {{base_url}}/api/error
HTTP 500
[Asserts]
jsonpath "$.error" exists
jsonpath "$.code" == 500

GET {{base_url}}/api/slow
HTTP 200
[Asserts]
jsonpath "$.message" contains "slow"
duration >= 3000
duration < 5000

# Invalid Request Tests
POST {{base_url}}/api/users
Content-Type: application/json
{
  "name": "",
  "email": ""
}
HTTP 400

POST {{base_url}}/api/products
Content-Type: application/json
{
  "name": "Invalid Product",
  "price": -10
}
HTTP 400

# Non-existent Endpoint
GET {{base_url}}/api/nonexistent
HTTP 404