import chromadb

client = chromadb.PersistentClient(path="./chroma_db")

collection = client.get_or_create_collection("agent_memory")

def store_memory(key: str, value: str):
    collection.add(documents=[value], ids=[key])

def retrieve_memory(key: str):
    results = collection.get(ids=[key])
    return results['documents'][0] if results['documents'] else None