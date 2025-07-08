import json
import os

def handler(event, context):
    """
    Função Lambda de exemplo que processa um evento e retorna uma saudação.
    """
    try:
        # Tenta parsear o corpo da requisição se for um evento de API Gateway
        if 'body' in event:
            body = json.loads(event['body'])
            name = body.get('name', 'Mundo')
        else:
            # Caso contrário, assume que o nome pode vir diretamente do evento
            name = event.get('name', 'Mundo')

        message = f"Olá, {name}! Esta é uma função Lambda Python."
        environment_var_example = os.getenv('FOO', 'Variável não definida')

        print(f"Mensagem gerada: {message}")
        print(f"Exemplo de variável de ambiente 'FOO': {environment_var_example}")

        response = {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": message,
                "environment_info": f"FOO: {environment_var_example}",
                "lambda_request_id": context.aws_request_id
            })
        }
        return response

    except Exception as e:
        print(f"Erro ao processar o evento: {e}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({"message": f"Erro interno do servidor: {str(e)}"})
        }

# Exemplo de como você testaria localmente (não executado pelo Lambda diretamente)
if __name__ == "__main__":
    test_event_code = {"name": "Testador de Código"}
    test_event_api_gateway = {
        "body": '{"name": "API Gateway User"}',
        "headers": {"Content-Type": "application/json"}
    }

    print("\n--- Teste Local (Implantação de Código) ---")
    os.environ['FOO'] = 'bar-code' # Simula variável de ambiente
    response_code = handler(test_event_code, type('obj', (object,), {'aws_request_id' : 'test-code-123'}))
    print(json.dumps(response_code, indent=2))

    print("\n--- Teste Local (Simulando API Gateway) ---")
    os.environ['FOO'] = 'bar-api-gw' # Simula variável de ambiente
    response_api_gw = handler(test_event_api_gateway, type('obj', (object,), {'aws_request_id' : 'test-api-gw-456'}))
    print(json.dumps(response_api_gw, indent=2))
