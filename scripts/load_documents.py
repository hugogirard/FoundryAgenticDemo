from azure.cosmos import ContainerProxy, CosmosClient
from openai import AzureOpenAI
from dotenv import load_dotenv
import json
import os
import uuid

def get_cosmos_container() -> ContainerProxy:
    client = CosmosClient.from_connection_string(os.getenv('COSMOS_DB_CONNECTION_STRING'))
    db = client.get_database_client("skyrim")
    db_container = db.get_container_client("")

def create_embedding():
    client = AzureOpenAI(
        api_key=os.getenv('AZURE_OPENAI_KEY'),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        azure_endpoint=os.getenv('AZURE_OPENAI_ENDPOINT')
    )
    embedding_model = os.getenv('AZURE_OPENAI_EMBEDDING_MODEL')

    with open("./dataset/crimes.json") as file:
        crimes = json.load(file)

    for crime in crimes:
        description = crime.get("description","")

        if description:
            response = client.embeddings.create(
                input=[description],
                model=embedding_model
            )
            description['descriptionVector'] = response.data[0].embedding

    return crimes

def main():
    load_dotenv(override=True)
    container = get_cosmos_container()
    documents = create_embedding()



if __name__ == "__main__":
    main()
