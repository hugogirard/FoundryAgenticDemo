import asyncio
from agent_framework.azure import AzureOpenAIChatClient
from azure.identity import DefaultAzureCredential
from config import Config
from contract import ChatRequest

class CrimeAgent():

    def __init__(self, config:Config):
        client = AzureOpenAIChatClient(
            credential=DefaultAzureCredential(),
            endpoint=config.open_ai_endpoint(),
 
        )

        self.agent = client.create_agent(
            instructions="You always tell funny joke",
            name="CrimeAgent"
        )

    async def chat(self,chat_request:ChatRequest) -> str:
        result = await self.agent.run(chat_request.question)
        return result.text
        
    