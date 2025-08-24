# Mosquitto MQTT Broker with JWT Authentication

[Acesse a versão em Português aqui](README-ptbr.md)

This project provides a configuration for the Mosquitto MQTT broker with JSON Web Tokens (JWT) based authentication. It uses the [mosquitto-jwt-auth](https://github.com/wiomoc/mosquitto-jwt-auth) plugin (written in Rust) to manage client authentication, allowing for robust and flexible access control.

The solution is packaged in a Docker container, facilitating deployment and management.


## Features

- **JWT Authentication**: Uses JWTs to authenticate MQTT clients, ensuring that only authorized clients can connect and interact with the broker.
- **MQTT and WebSockets Support**: The broker is configured to accept standard MQTT connections on port `1883` and MQTT over WebSockets connections on port `9001`.
- **Secure Configuration**: Disables anonymous access and requires a JWT secret for token validation.
- **Easy Deployment with Docker**: The `Dockerfile` automates the compilation of Mosquitto and the JWT plugin, creating a lightweight and ready-to-use image.

## Project Structure

```
.
├── .dockerignore             # Files to be ignored by Docker
├── .gitignore                # Files to be ignored by Git
├── Dockerfile                # Docker image definition
├── entrypoint.sh             # Container startup script
└── mosquitto.conf            # Mosquitto configuration
```

## How to Use

### Prerequisites

- Docker

### 1. Build the Docker Image

Navigate to the project's root directory and build the Docker image:

```bash
docker build -t mosquitto-jwt-broker .
```

### 2. Run the Container

The Mosquitto broker requires a JWT secret (`JWT_SECRET`) to function. This secret is used to sign and verify JWT tokens.

```bash
docker run -d \
  -p 1883:1883 \
  -p 9001:9001 \
  -e JWT_SECRET="your_jwt_secret_here" \
  mosquitto-jwt-broker
```

Replace `"your_jwt_secret_here"` with a strong and unique secret string.

### 3. Generate JWT Tokens

MQTT clients will need a valid JWT to connect. The token must be signed with the `JWT_SECRET` configured in the broker.

A typical JWT for this setup might have the following claims:

```json
{
  "subs": ["topic/to/subscribe", "another/topic"],
  "publ": ["topic/to/publish", "yet/another/topic"]
}
```

- `subs`: Array of topics the client is allowed to subscribe to.
- `publ`: Array of topics the client is allowed to publish to.

You can use online tools (like [jwt.io](https://jwt.io/)) or programming libraries to generate these tokens.

## Mosquitto Configuration (`mosquitto.conf`)

The `mosquitto.conf` file contains the following key configurations:

- `listener 1883 0.0.0.0`: Enables the standard MQTT listener on port 1883.
- `listener 9001 0.0.0.0` and `protocol websockets`: Enables the MQTT over WebSockets listener on port 9001.
- `allow_anonymous false`: Disables unauthenticated connections.
- `auth_plugin /mosquitto/plugins/libmosquitto_jwt_auth.so`: Loads the JWT authentication plugin.
- `auth_opt_jwt_alg HS256`: Sets the JWT signing algorithm to HS256.
- `auth_opt_jwt_sec_file /mosquitto/config/jwt_secret.key`: Specifies the path to the file containing the JWT secret.
- `auth_opt_jwt_validate_exp false`: Disables token expiration validation (can be changed to `true` in production).
- `auth_opt_jwt_validate_sub_match_username false`: Disables validation that the JWT `sub` claim must match the MQTT username.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
