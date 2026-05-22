import json

from azure.identity import ClientSecretCredential
from azure.servicebus import ServiceBusClient, ServiceBusMessage

with open("./terraform.tfstate", "r") as f:
    tfstate = json.load(f)

fully_qualified_namespace = tfstate["outputs"]["service_bus_namespace_name"]["value"]
fully_qualified_namespace = f"{fully_qualified_namespace}.servicebus.windows.net"
sb_queue = tfstate["outputs"]["service_bus_queue_name"]["value"]

credential = ClientSecretCredential(
    tenant_id=tfstate["outputs"]["current_tenant_id"]["value"],
    client_id=tfstate["outputs"]["service_principal_client_id"]["value"],
    client_secret=tfstate["outputs"]["service_principal_password"]["value"]
)

with ServiceBusClient(fully_qualified_namespace, credential) as client:
    with client.get_queue_sender(queue_name=sb_queue) as sender:
        message = ServiceBusMessage("Hello from Client Secret!")
        sender.send_messages(message)

with ServiceBusClient(fully_qualified_namespace, credential) as client:
    with client.get_queue_receiver(queue_name=sb_queue, max_wait_time=5) as receiver:
        for msg in receiver:
            print(f"Received: {msg}")
            receiver.complete_message(msg)
