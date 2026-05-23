import os
import asyncio

from azure.identity.aio import ClientSecretCredential
from azure.servicebus.aio import ServiceBusClient


async def process_message(message):
    """
    Your business logic goes here.
    """

    print(f"Processing message: {str(message)}")

    # Simulate async work
    await asyncio.sleep(2)

    print("Done")


async def main():
    credential = ClientSecretCredential(
        tenant_id=os.environ["AZURE_TENANT_ID"],
        client_id=os.environ["AZURE_CLIENT_ID"],
        client_secret=os.environ["AZURE_CLIENT_SECRET"]
    )

    servicebus_client = ServiceBusClient(
        fully_qualified_namespace=os.environ["SB_FULLY_QUALIFIED_NAMESPACE"],
        credential=credential
    )

    async with servicebus_client:
        receiver = servicebus_client.get_queue_receiver(
            queue_name=os.environ["QUEUE_NAME"]
        )

        async with receiver:
            print("Listening for messages...")

            while True:
                print("Receiving messages...")
                messages = await receiver.receive_messages(
                    max_message_count=10,
                    max_wait_time=5,
                )
                print(f"Received {len(messages)} messages")
                for message in messages:
                    try:
                        print(f"Processing message: {str(message)}")
                        await process_message(message)

                        await receiver.complete_message(message)

                    except Exception as e:
                        print(f"Error processing message: {e}")

                        await receiver.abandon_message(message)


if __name__ == "__main__":
    asyncio.run(main())
