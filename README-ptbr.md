# Mosquitto MQTT Broker com Autenticação JWT

Este projeto fornece uma configuração do broker MQTT Mosquitto com autenticação baseada em JSON Web Tokens (JWT). Ele utiliza o plugin [mosquitto-jwt-auth](https://github.com/wiomoc/mosquitto-jwt-auth) para gerenciar a autenticação de clientes, permitindo um controle de acesso robusto e flexível.

A solução é empacotada em um contêiner Docker, facilitando a implantação e o gerenciamento.

## Funcionalidades

- **Autenticação JWT**: Utiliza JWTs para autenticar clientes MQTT, garantindo que apenas clientes autorizados possam se conectar e interagir com o broker.
- **Suporte a MQTT e WebSockets**: O broker está configurado para aceitar conexões MQTT padrão na porta `1883` e conexões MQTT sobre WebSockets na porta `9001`.
- **Configuração Segura**: Desabilita o acesso anônimo e exige um segredo JWT para a validação dos tokens.
- **Fácil Implantação com Docker**: O `Dockerfile` automatiza a compilação do Mosquitto e do plugin JWT, criando uma imagem leve e pronta para uso.

## Estrutura do Projeto

```
.
├── .dockerignore             # Arquivos a serem ignorados pelo Docker
├── .gitignore                # Arquivos a serem ignorados pelo Git
├── Dockerfile                # Definição da imagem Docker
├── entrypoint.sh             # Script de inicialização do contêiner
└── mosquitto.conf            # Configuração do Mosquitto
```

## Como Usar

### Pré-requisitos

- Docker

### 1. Construir a Imagem Docker

Navegue até o diretório raiz do projeto e construa a imagem Docker:

```bash
docker build -t mosquitto-jwt-broker .
```

### 2. Executar o Contêiner

O broker Mosquitto requer um segredo JWT (`JWT_SECRET`) para funcionar. Este segredo é usado para assinar e verificar os tokens JWT.

```bash
docker run -d \
  -p 1883:1883 \
  -p 9001:9001 \
  -e JWT_SECRET="seu_segredo_jwt_aqui" \
  mosquitto-jwt-broker
```

Substitua `"seu_segredo_jwt_aqui"` por uma string secreta forte e única.

### 3. Gerar Tokens JWT

Os clientes MQTT precisarão de um JWT válido para se conectar. O token deve ser assinado com o `JWT_SECRET` configurado no broker.

Um JWT típico para este setup pode ter as seguintes claims:

```json
{
  "subs": ["topic/to/subscribe", "another/topic"],
  "publ": ["topic/to/publish", "yet/another/topic"]
}
```

- `subs`: Array de tópicos aos quais o cliente tem permissão para subscrever.
- `publ`: Array de tópicos aos quais o cliente tem permissão para publicar.

Você pode usar ferramentas online (como [jwt.io](https://jwt.io/)) ou bibliotecas de programação para gerar esses tokens.

## Configuração do Mosquitto (`mosquitto.conf`)

O arquivo `mosquitto.conf` contém as seguintes configurações chave:

- `listener 1883 0.0.0.0`: Habilita o listener MQTT padrão na porta 1883.
- `listener 9001 0.0.0.0` e `protocol websockets`: Habilita o listener MQTT sobre WebSockets na porta 9001.
- `allow_anonymous false`: Desabilita conexões sem autenticação.
- `auth_plugin /mosquitto/plugins/libmosquitto_jwt_auth.so`: Carrega o plugin de autenticação JWT.
- `auth_opt_jwt_alg HS256`: Define o algoritmo de assinatura JWT como HS256.
- `auth_opt_jwt_sec_file /mosquitto/config/jwt_secret.key`: Especifica o caminho para o arquivo que contém o segredo JWT.
- `auth_opt_jwt_validate_exp false`: Desabilita a validação da expiração do token (pode ser alterado para `true` em produção).
- `auth_opt_jwt_validate_sub_match_username false`: Desabilita a validação de que o `sub` do JWT deve corresponder ao nome de usuário MQTT.

## Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
