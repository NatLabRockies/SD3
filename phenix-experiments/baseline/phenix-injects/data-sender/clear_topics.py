from kafka import KafkaAdminClient
import argparse

parser = argparse.ArgumentParser()

parser.add_argument(
    "--b",
    default="localhost",
    help="Kafka broker IP"
)
parser.add_argument(
    "--e",
    help="Experiment name to clear topics from"
)
args = parser.parse_args()
print(args.b)

experiment_name = "sd3-mini-ag"
admin_client = KafkaAdminClient(bootstrap_servers=f"{args.b}:9092")

topics = admin_client.list_topics()
selected = []
for topic in topics:
    if topic.split(".")[0] == args.e:
        selected.append(topic)
        
admin_client.delete_topics(topics=selected)
print(f"deleted topics {selected}")